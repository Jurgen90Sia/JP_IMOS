# frozen_string_literal: true
require_relative '../materials/catalog'
require_relative '../physical/rectangular_part'
require_relative 'physical_record'
require_relative 'physical_snapshot'
module JPImosPro
  module Design
    module PhysicalState
      SCHEMA='jpimos.physical-design/1'
      PROFILE='jp-physical-design-v1'
      module_function
      def boundary(limits)
        result=ProjectCore.boundary(limits) { |budget| yield budget }
        result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
        result
      end
      def validate(state:,limits: {})
        boundary(limits) { |budget| PhysicalRecord.validate(state,budget)[0] }
      end
      def encode(state:,limits: {})
        boundary(limits) { |budget| ProjectCore::Codec.encode(PhysicalRecord.validate(state,budget)[0],budget) }
      end
      def decode(source:,limits: {})
        boundary(limits) { |budget| PhysicalRecord.validate(ProjectCore::Codec.parse(source,budget),budget)[0] }
      end
      def resolve(state:,numeric_policy:,limits: {})
        boundary(limits) do |budget|
          owned,report=PhysicalRecord.validate(state,budget)
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          {'state'=>owned,'snapshot'=>PhysicalSnapshot.build(owned,report,policy,budget)}.freeze
        end
      end
      def prepare_revision(current:,replacement:,expected_revision:,numeric_policy:,limits: {})
        boundary(limits) do |budget|
          before,_=PhysicalRecord.validate(current,budget,'/current')
          begin
            ProjectCore::Revision.check_current(before['design']['project'],expected_revision)
          rescue ProjectCore::Fault => e
            path=e.json_pointer.start_with?('/current') ? '/current/design/project'+e.json_pointer.delete_prefix('/current') : e.json_pointer
            raise ProjectCore::Fault.new(e.code,path,e.entity_ref,e.details,e.engine)
          end
          after,_,positions=PhysicalRecord.validate(replacement,budget,'/replacement')
          begin
            ProjectCore::Revision.check_replacement(before['design']['project'],after['design']['project'],budget)
          rescue ProjectCore::Fault => e
            path=e.json_pointer.sub(%r{\A/(current|replacement)}) { |prefix| prefix+'/design/project' }
            raise ProjectCore::Fault.new(e.code,path,e.entity_ref,e.details,e.engine)
          end
          PhysicalRecord.check_transition(before,after,budget,positions)
          raise ProjectCore::Fault.new('E_NO_CHANGE','/replacement') if ProjectCore::Revision.semantic_equal?(before,after,budget)
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          revision=before['design']['project']['revision']+1
          project=after['design']['project'].merge('revision'=>revision).freeze
          design=after['design'].merge('project'=>project).freeze
          state=after.merge('design'=>design).freeze
          index=after['catalog']['entries'].each_with_object({}) do |entry,h|
            budget.tick('/replacement/catalog');h[[entry['id'],entry['version']]]=entry
          end
          _,report=PhysicalRecord.scoped('/replacement/design') { Materials::Catalog.resolve_owned(design,index,budget) }
          snapshot=PhysicalRecord.scoped('/replacement') { PhysicalSnapshot.build(state,report,policy,budget) }
          {'project_id'=>project['project_id'],'base_revision'=>revision-1,'next_revision'=>revision,'state'=>state,'snapshot'=>snapshot}.freeze
        end
      end
    end
  end
end
