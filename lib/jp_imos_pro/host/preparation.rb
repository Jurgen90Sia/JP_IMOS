# frozen_string_literal: true
require_relative 'reader'
module JPImosPro
  module Host
    module Preparation
      module_function
      def with_lease(lease,numeric_policy,limits)
        Registry.boundary(limits) do |budget,_|
          unless lease.instance_of?(Lease)
            raise ProjectCore::Fault.new('E_HOST_LEASE_CONFLICT','/host/lease')
          end
          authority=lease.authority
          authority.with_guard do
            authority.validate_lease(lease,mutation:true)
            policy=ProjectCore::Document.new(budget).deep_freeze(ProjectCore.validated_policy(numeric_policy,budget))
            unless policy==lease.policy
              raise ProjectCore::Fault.new('E_NUMERIC_POLICY_CONFLICT','/numeric_policy')
            end
            projection=yield lease,budget,policy
            authority.register_candidate(lease,projection,policy)
          end
        end
      end
      def initial(lease:,state:,numeric_policy:,limits: {})
        with_lease(lease,numeric_policy,limits) do |base,budget,policy|
          raise ProjectCore::Fault.new('E_HOST_OWNERSHIP_CONFLICT','/host/document') unless base.document.nil?
          owned,snapshot,_=Design::PhysicalCheckpoint.fresh(state,policy,budget)
          Projection.from_owned_resolution(state:owned,snapshot:snapshot,numeric_policy:policy,budget:budget)
        end
      end
      def revision(lease:,replacement:,expected_revision:,numeric_policy:,limits: {})
        with_lease(lease,numeric_policy,limits) do |base,budget,policy|
          raise ProjectCore::Fault.new('E_HOST_OWNERSHIP_CONFLICT','/host/document') if base.document.nil?
          value=Design::PhysicalState.prepare_revision_with_budget(current:base.projection.state,replacement:replacement,
            expected_revision:expected_revision,numeric_policy:policy,budget:budget)
          Projection.from_owned_resolution(state:value['state'],snapshot:value['snapshot'],numeric_policy:policy,budget:budget)
        end
      end
    end
  end
end
