# frozen_string_literal: true
require_relative 'projection'

module JPImosPro
  module Host
    class DecodedDocument
      attr_reader :document,:projection
      def initialize(document,projection)
        @document,@projection=document,projection
        freeze
      end
      private_class_method :new
    end

    module DocumentCodec
      SCHEMA='jpimos.host-document/1'
      MANIFEST_SCHEMA='jpimos.host-manifest/1'
      SCOPE='controlled_scratch'
      UINT64_MAX='18446744073709551615'
      FIELDS=%w[schema scope profile project_id root_id acceptance_id checkpoint projection content_sha256].freeze
      module_function

      def boundary(limits)
        result=ProjectCore.boundary(limits) { |budget| yield budget }
        result[:metadata]={schema:SCHEMA,profile_version:Projection::PROFILE,mutation_state:'unchanged'}
        result
      end
      def encode(state:,root_id:,acceptance_id:,manifest:,numeric_policy:,limits: {})
        boundary(limits) do |budget|
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          owned,snapshot,_=Design::PhysicalCheckpoint.fresh(state,policy,budget)
          projection=Projection.from_owned_resolution(state:owned,snapshot:snapshot,numeric_policy:policy,budget:budget)
          encode_owned(projection:projection,root_id:root_id,acceptance_id:acceptance_id,manifest:manifest,budget:budget)
        end
      end
      # Trusted same-request projection only; native ownership is not checked.
      def encode_owned(projection:,root_id:,acceptance_id:,manifest:,budget:)
        record=record_owned(projection:projection,root_id:root_id,acceptance_id:acceptance_id,manifest:manifest,budget:budget)
        ProjectCore::Codec.encode(record,budget)
      end
      def record_owned(projection:,root_id:,acceptance_id:,manifest:,budget:)
        validator=ProjectCore::Document.new(budget)
        body=validator.copy({'schema'=>SCHEMA.dup,'scope'=>SCOPE.dup,'profile'=>Projection::PROFILE.dup,
          'project_id'=>projection.plan['project_id'],'root_id'=>root_id,'acceptance_id'=>acceptance_id,
          'checkpoint'=>projection.checkpoint_record,'projection'=>manifest})
        validate_envelope(body,validator)
        validate_manifest(body['projection'],projection,budget)
        validate_identity(body,projection)
        checksum=Design::PhysicalSnapshot.digest(body,budget)
        output=validator.copy(body.merge('content_sha256'=>checksum))
        validator.deep_freeze(output)
      end
      def decode(source:,numeric_policy:,limits: {})
        boundary(limits) { |budget| decode_with_budget(source:source,numeric_policy:numeric_policy,budget:budget) }
      end
      def decode_with_budget(source:,numeric_policy:,budget:)
        validator=ProjectCore::Document.new(budget)
        data=validator.copy(ProjectCore::Codec.parse(source,budget))
        version(data,'schema',SCHEMA,'/schema')
        Materials::Context.keys(data,FIELDS,'')
        validate_envelope(data,validator)
        Design::PhysicalCheckpoint.sha(data['content_sha256'],'/content_sha256')
        body=data.reject { |key,_| key=='content_sha256' }
        unless Design::PhysicalSnapshot.digest(body,budget)==data['content_sha256']
          raise ProjectCore::Fault.new('E_CHECKPOINT_INTEGRITY','/content_sha256')
        end
        policy=ProjectCore.validated_policy(numeric_policy,budget)
        rebuilt=Design::PhysicalRecord.scoped('/checkpoint') do
          Design::PhysicalCheckpoint.rebuild_owned_record(record:data['checkpoint'],numeric_policy:policy,budget:budget)
        end
        projection=Projection.from_owned_resolution(state:rebuilt['state'],snapshot:rebuilt['snapshot'],numeric_policy:policy,budget:budget)
        validate_manifest(data['projection'],projection,budget)
        validate_identity(data,projection)
        DecodedDocument.send(:new,validator.deep_freeze(data),projection)
      end
      def version(data,key,expected,path)
        if data.instance_of?(Hash) && data.key?(key) && data[key]!=expected
          raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED',path)
        end
      end
      def validate_envelope(data,validator)
        version(data,'schema',SCHEMA,'/schema')
        version(data,'profile',Projection::PROFILE,'/profile')
        unless data.instance_of?(Hash) && data['scope']==SCOPE
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/scope')
        end
        %w[project_id acceptance_id].each { |key| validator.check(data[key],:uuid,'/'+key) }
        validator.check(data['root_id'],:uuid,'/root_id') unless data['root_id'].nil?
      end
      def hint(value,budget,path)
        budget.tick(path)
        return if value.nil?
        unless value.instance_of?(String) && value.size<=20 && /\A[1-9][0-9]*\z/.match?(value) &&
            (value.size<20 || value<=UINT64_MAX)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path)
        end
      end
      def ownership(path)
        raise ProjectCore::Fault.new('E_HOST_OWNERSHIP_CONFLICT',path)
      end
      def validate_manifest(data,projection,budget)
        version(data,'schema',MANIFEST_SCHEMA,'/projection/schema')
        Materials::Context.keys(data,%w[schema plan_sha256 root_pid_hint parts],'/projection')
        Design::PhysicalCheckpoint.sha(data['plan_sha256'],'/projection/plan_sha256')
        unless data['plan_sha256']==projection.plan_sha256
          raise ProjectCore::Fault.new('E_HOST_GEOMETRY_CONFLICT','/projection/plan_sha256')
        end
        hint(data['root_pid_hint'],budget,'/projection/root_pid_hint')
        parts=data['parts'];expected=projection.plan['parts']
        raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/projection/parts') unless parts.instance_of?(Array)
        ownership('/projection/parts') unless parts.size==expected.size
        parts.each_with_index do |part,i|
          path="/projection/parts/#{i}";budget.tick(path)
          Materials::Context.keys(part,%w[part_id container_pid_hint solids],path)
          ownership(path+'/part_id') unless part['part_id']==expected[i]['part_id']
          hint(part['container_pid_hint'],budget,path+'/container_pid_hint')
          solids=part['solids'];wanted=expected[i]['solids']
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path+'/solids') unless solids.instance_of?(Array)
          ownership(path+'/solids') unless solids.size==wanted.size
          solids.each_with_index do |solid,j|
            p=path+"/solids/#{j}";budget.tick(p)
            Materials::Context.keys(solid,%w[component source_index pid_hint],p)
            %w[component source_index].each do |key|
              ownership(p+'/'+key) unless solid[key]==wanted[j][key]
            end
            hint(solid['pid_hint'],budget,p+'/pid_hint')
          end
        end
      end
      def validate_identity(data,projection)
        ownership('/project_id') unless data['project_id']==projection.plan['project_id']
        empty=projection.plan['parts'].empty?
        ownership('/root_id') unless data['root_id'].nil? == empty
        ownership('/projection/root_pid_hint') if empty && !data['projection']['root_pid_hint'].nil?
      end
    end
  end
end
