# frozen_string_literal: true
require 'securerandom'
require_relative 'document_codec'

module JPImosPro
  module Host
    # Opaque process objects, never wire inputs or Marshal persistence.
    module Opaque
      def _dump(*)
        raise TypeError,'host process identity cannot be persisted'
      end
    end
    class ModelAnchor
      include Opaque
      attr_reader :model,:nonce
      def initialize(model)
        @model,@nonce=model,SecureRandom.uuid.freeze
        freeze
      end
      private_class_method :new
    end
    class Context
      include Opaque
      attr_reader :port,:authority
      def initialize(port,authority)
        @port,@authority=port,authority
        freeze
      end
      private_class_method :new
    end
    class ControlledGrant
      include Opaque
      private_class_method :new
    end
    class VisitBudget
      attr_reader :used
      def initialize(limit)
        unless limit.instance_of?(Integer) && limit>0 && limit<=50_000
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/limits/entity_visits')
        end
        @limit,@used=limit,0
      end
      def tick(count=1)
        unless count.instance_of?(Integer) && count>0
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/host/entities')
        end
        @used+=count
        raise ProjectCore::Fault.new('E_RESOURCE_LIMIT','/host/entities') if @used>@limit
      end
    end

    class Authority
      include Opaque
      attr_reader :anchor,:epoch,:sequence
      def initialize(anchor)
        @anchor=anchor
        @contexts={}.compare_by_identity
        @leases={}.compare_by_identity
        @candidates={}.compare_by_identity
        @sequence=0;@epoch=SecureRandom.uuid.freeze
        @busy=false;@revoked=false;@quarantined=false;@settled=false
      end
      private_class_method :new
      def fault(code='E_HOST_LEASE_CONFLICT')
        raise ProjectCore::Fault.new(code,'/host/session')
      end
      def check_thread
        fault('E_HOST_CONTEXT_UNSUPPORTED') unless Thread.current.equal?(Thread.main)
      end
      def check_live
        check_thread
        fault if @revoked
      end
      def attach(port)
        check_live
        context=Context.send(:new,port,self)
        @contexts[context]=true
        context
      end
      def registered_context?(context)
        context.instance_of?(Context) && @contexts.key?(context)
      end
      def validate_context(context)
        check_live
        fault('E_HOST_CONTEXT_UNSUPPORTED') unless registered_context?(context)
        fault('E_HOST_CONTEXT_UNSUPPORTED') unless port_call { context.port.anchor.equal?(@anchor) }
      end
      # Only adapter calls are translated here; pure-core programming errors
      # remain visible. Adapter uncertainty never clears shared quarantine.
      def port_call
        yield
      rescue ProjectCore::Fault
        raise
      rescue StandardError => e
        quarantine!
        raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/port',nil,{'exception_class'=>e.class.name})
      end
      def with_guard
        check_live
        fault('E_HOST_REENTRANT') if @busy
        @busy=true
        begin
          yield
        ensure
          @busy=false
        end
      end
      # Trusted harness assertion: its native action has settled. This is not
      # an SDK operation-state query and must never be minted by observers.
      def issue_grant(context)
        validate_context(context)
        @grant=ControlledGrant.send(:new).freeze
        @grant_used=false;@settled=true
        @grant
      end
      def advance
        @sequence+=1
        @leases.clear;@candidates.clear
      end
      def before_action!
        check_live
        advance;@settled=false;@grant=nil
      end
      def quarantine!
        check_live
        advance;@epoch=SecureRandom.uuid.freeze
        @quarantined=true;@settled=false;@grant=nil
      end
      alias notify_external! quarantine!
      def quarantined?;@quarantined;end
      def revoke!
        before_action!;@revoked=true
      end
      def begin_read(context,grant)
        validate_context(context)
        unless @settled && grant.instance_of?(ControlledGrant) && grant.equal?(@grant) && !@grant_used &&
            port_call { context.port.controlled_grant.equal?(grant) }
          fault('E_HOST_QUIESCENCE_UNPROVEN')
        end
        @grant_used=true
        advance
        [@epoch,@sequence].freeze
      end
      def check_ticket(ticket)
        check_live
        fault unless ticket==[@epoch,@sequence] && @settled
      end
      def publish_lease(context,ticket,raw,document,projection,inspection,policy,recovery)
        check_ticket(ticket)
        if recovery
          @epoch=SecureRandom.uuid.freeze
          @quarantined=false
        end
        lease=Lease.send(:new,self,context,@epoch,@sequence,raw,document,projection,inspection,policy,@quarantined)
        @leases[lease]=true
        lease
      end
      def validate_lease(lease,mutation:false)
        check_live
        unless lease.instance_of?(Lease) && @leases.key?(lease) && lease.authority.equal?(self) &&
            lease.epoch==@epoch && lease.sequence==@sequence
          fault
        end
        validate_context(lease.context)
        fault('E_HOST_RECOVERY_REQUIRED') if mutation && (@quarantined || lease.read_only?)
        fault('E_HOST_QUIESCENCE_UNPROVEN') if mutation && !@settled
        lease
      end
      def register_candidate(lease,projection,policy)
        validate_lease(lease,mutation:true)
        candidate=Candidate.send(:new,self,lease,projection,policy)
        @candidates[candidate]=false
        candidate
      end
      def validate_candidate(candidate)
        check_live
        unless candidate.instance_of?(Candidate) && @candidates.key?(candidate) && !@candidates[candidate] &&
            candidate.authority.equal?(self)
          fault
        end
        validate_lease(candidate.base_lease,mutation:true)
        candidate
      end
      def consume_candidate(candidate)
        validate_candidate(candidate)
        @candidates[candidate]=true
        candidate
      end
    end

    module Registry
      @models={}.compare_by_identity
      module_function
      # Trusted model lifecycle entry points. Only the native harness may claim
      # open/close/settled transitions; arbitrary callers are not isolated.
      def open(model:)
        raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/model') unless Thread.current.equal?(Thread.main) && !model.nil?
        return @models[model].anchor if @models.key?(model)
        anchor=ModelAnchor.send(:new,model)
        @models[model]=Authority.send(:new,anchor)
        anchor
      end
      def authority(anchor)
        unless anchor.instance_of?(ModelAnchor) && @models[anchor.model] && @models[anchor.model].anchor.equal?(anchor)
          raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/anchor')
        end
        @models[anchor.model]
      end
      def attach(port:)
        authority(port.anchor).attach(port)
      end
      def context_authority(context)
        unless context.instance_of?(Context) && context.authority.registered_context?(context)
          raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/context')
        end
        context.authority.validate_context(context)
        context.authority
      end
      def issue_grant(context:)
        context_authority(context).issue_grant(context)
      end
      def close(anchor:)
        a=authority(anchor);a.revoke!;@models.delete(anchor.model)
      end
      def boundary(limits)
        unless limits.instance_of?(Hash)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/limits')
        end
        visits=VisitBudget.new(limits.fetch(:entity_visits,50_000))
        result=ProjectCore.boundary(limits.reject { |key,_| key==:entity_visits }) { |budget| yield budget,visits }
        result[:metadata]={schema:'jpimos.host-session/1',profile_version:Projection::PROFILE,mutation_state:'unchanged'}
        result
      rescue ProjectCore::Fault => e
        {ok:false,value:nil,diagnostics:[e.diagnostic],metadata:{schema:'jpimos.host-session/1',profile_version:Projection::PROFILE,mutation_state:'unchanged'}}
      end
    end
  end
end
