# frozen_string_literal: true
require_relative 'construction'
require_relative 'design/record'
require_relative 'design/snapshot'
module JPImosPro
  module Design
    SCHEMA='jpimos.carcass-design/1'
    PROFILE='jp-carcass-design-v1'
    module_function
    def boundary(limits)
      result=ProjectCore.boundary(limits) { |budget| yield budget }
      result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
      result
    end
    def validate(state:,limits: {})
      boundary(limits) { |budget| Record.validate(state,budget) }
    end
    def encode(state:,limits: {})
      boundary(limits) { |budget| ProjectCore::Codec.encode(Record.validate(state,budget),budget) }
    end
    def decode(source:,limits: {})
      boundary(limits) { |budget| Record.validate(ProjectCore::Codec.parse(source,budget),budget) }
    end
    def current_guard(project,expected)
      ProjectCore::Revision.check_current(project,expected)
    rescue ProjectCore::Fault => e
      path=e.json_pointer.start_with?('/current') ? '/current/project'+e.json_pointer.delete_prefix('/current') : e.json_pointer
      raise ProjectCore::Fault.new(e.code,path,e.entity_ref,e.details,e.engine)
    end
    def replacement_guard(current,replacement,budget)
      ProjectCore::Revision.check_replacement(current,replacement,budget)
    rescue ProjectCore::Fault => e
      path=e.json_pointer.start_with?('/replacement') ? '/replacement/project'+e.json_pointer.delete_prefix('/replacement') : e.json_pointer
      raise ProjectCore::Fault.new(e.code,path,e.entity_ref,e.details,e.engine)
    end
    def prepare_revision(current:,replacement:,expected_revision:,numeric_policy:,limits: {})
      policy=nil
      result=boundary(limits) do |budget|
        before=Record.validate(current,budget,'/current')
        current_guard(before['project'],expected_revision)
        after=Record.validate(replacement,budget,'/replacement')
        replacement_guard(before['project'],after['project'],budget)
        if ProjectCore::Revision.semantic_equal?(before,after,budget)
          raise ProjectCore::Fault.new('E_NO_CHANGE','/replacement')
        end
        policy=ProjectCore.validated_policy(numeric_policy,budget)
        next_revision=before['project']['revision']+1
        budget.tick('/replacement',after.size+after['project'].size+5)
        project=after['project'].merge('revision'=>next_revision).freeze
        candidate=after.merge('project'=>project).freeze
        begin
          snapshot=Snapshot.build(candidate,policy,budget)
        rescue ProjectCore::Fault => e
          raise ProjectCore::Fault.new(e.code,'/replacement'+e.json_pointer,e.entity_ref,e.details,e.engine)
        end
        {'project_id'=>project['project_id'],'base_revision'=>before['project']['revision'],'next_revision'=>next_revision,
          'state'=>candidate,'snapshot'=>snapshot}.freeze
      end
      result[:metadata]=result[:metadata].merge(policy) if policy
      result
    end
  end
end
