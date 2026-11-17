# frozen_string_literal: true
require_relative 'physical_state'

module JPImosPro
  module Design
    module PhysicalCheckpoint
      SCHEMA='jpimos.physical-checkpoint/1'
      PROFILE='jp-physical-checkpoint-v1'
      FIELDS=%w[project_id revision state_sha256 catalog_sha256 snapshot_sha256 policy_id backend_id].freeze
      module_function

      def boundary(limits)
        result=ProjectCore.boundary(limits) { |budget| yield budget }
        result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
        result
      end
      def fresh(state,policy,budget)
        owned,report=PhysicalRecord.validate(state,budget)
        snapshot=PhysicalSnapshot.build(owned,report,policy,budget)
        [owned,snapshot,resolution_verification(snapshot,policy,budget)]
      end
      def resolution_verification(snapshot,policy,budget)
        verification={'project_id'=>snapshot['project_id'],'revision'=>snapshot['source_revision'],
          'state_sha256'=>snapshot['state_sha256'],'catalog_sha256'=>snapshot['catalog_sha256'],
          'snapshot_sha256'=>snapshot['content_sha256'],'policy_id'=>policy[:policy_id].dup,'backend_id'=>policy[:backend_id].dup}
        ProjectCore::Document.new(budget).deep_freeze(verification)
        verification
      end
      # Trusted composition only: source and snapshot were rebuilt together by
      # this core. Header checks catch accidental mixing, not hostile snapshots.
      # Public wire entry points always validate/rebuild source through fresh.
      def record_from_owned_resolution(state:,snapshot:,numeric_policy:,budget:)
        project=state['design']['project']
        expected={'project_id'=>project['project_id'],'source_revision'=>project['revision'],
          'state_sha256'=>PhysicalSnapshot.digest(state,budget)}
        expected.each do |key,value|
          budget.tick('/snapshot/'+key)
          raise ProjectCore::Fault.new('E_CHECKPOINT_MISMATCH','/snapshot/'+key) unless snapshot[key]==value
        end
        %w[policy_id backend_id].each do |key|
          budget.tick('/snapshot/design_snapshot/'+key)
          unless snapshot['design_snapshot'][key]==numeric_policy[key.to_sym]
            raise ProjectCore::Fault.new('E_NUMERIC_POLICY_CONFLICT','/snapshot/design_snapshot/'+key)
          end
        end
        verification=resolution_verification(snapshot,numeric_policy,budget)
        validator=ProjectCore::Document.new(budget)
        payload=validator.copy({'schema'=>SCHEMA.dup,'state'=>state,'verification'=>verification})
        checksum=Digest::SHA256.hexdigest(ProjectCore::Codec.encode(payload,budget))
        validator.deep_freeze(validator.copy(payload.merge('content_sha256'=>checksum)))
      end
      def encode(state:,numeric_policy:,limits: {})
        boundary(limits) do |budget|
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          owned,snapshot,_=fresh(state,policy,budget)
          output=record_from_owned_resolution(state:owned,snapshot:snapshot,numeric_policy:policy,budget:budget)
          ProjectCore::Codec.encode(output,budget)
        end
      end
      def sha(value,path)
        unless value.instance_of?(String) && /\A[0-9a-f]{64}\z/.match?(value)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path)
        end
      end
      def verification_format(value,budget)
        Materials::Context.keys(value,FIELDS,'/verification')
        validator=ProjectCore::Document.new(budget)
        validator.check(value['project_id'],:uuid,'/verification/project_id')
        validator.check(value['revision'],:revision,'/verification/revision')
        %w[state_sha256 catalog_sha256 snapshot_sha256].each { |key| sha(value[key],'/verification/'+key) }
        begin
          ProjectCore.validated_policy({policy_id:value['policy_id'],backend_id:value['backend_id']},budget)
        rescue ProjectCore::Fault => e
          raise ProjectCore::Fault.new(e.code,'/verification'+e.json_pointer.delete_prefix('/numeric_policy'),e.entity_ref,e.details,e.engine)
        end
      end
      def decode(source:,numeric_policy:,limits: {})
        boundary(limits) do |budget|
          data=ProjectCore::Codec.parse(source,budget)
          if data.instance_of?(Hash) && data.key?('schema') && data['schema']!=SCHEMA
            raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED','/schema')
          end
          Materials::Context.keys(data,%w[schema state verification content_sha256],'')
          sha(data['content_sha256'],'/content_sha256')
          stored=verification_format(data['verification'],budget)
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          unless stored==policy
            raise ProjectCore::Fault.new('E_NUMERIC_POLICY_CONFLICT','/verification')
          end
          body=data.reject { |key,_| key=='content_sha256' }
          unless PhysicalSnapshot.digest(body,budget)==data['content_sha256']
            raise ProjectCore::Fault.new('E_CHECKPOINT_INTEGRITY','/content_sha256')
          end
          state,snapshot,expected=fresh(data['state'],policy,budget)
          FIELDS.each do |key|
            budget.tick('/verification/'+key)
            unless expected[key]==data['verification'][key]
              raise ProjectCore::Fault.new('E_CHECKPOINT_MISMATCH','/verification/'+key)
            end
          end
          {'state'=>state,'snapshot'=>snapshot,'verification'=>expected,'content_sha256'=>data['content_sha256'].freeze}.freeze
        end
      end
    end
  end
end
