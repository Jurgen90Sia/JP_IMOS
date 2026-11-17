# frozen_string_literal: true
require_relative 'preparation'

module JPImosPro
  module Host
    module Application
      module_function
      def fault(code,path='/host/application',details={})
        raise ProjectCore::Fault.new(code,path,nil,details)
      end
      # During a transaction the abort protocol, rather than this helper,
      # decides whether uncertainty requires quarantine.
      def port_call
        yield
      rescue ProjectCore::Fault
        raise
      rescue StandardError,Interrupt => e
        fault('E_HOST_CONTEXT_UNSUPPORTED','/host/port',{'exception_class'=>e.class.name})
      end
      def require_true(path)
        fault('E_HOST_CONTEXT_UNSUPPORTED',path) unless port_call { yield }==true
      end
      def apply(context:,candidate:,limits: {})
        mutation='unchanged'
        result=Registry.boundary(limits) do |budget,visits|
          authority=Registry.context_authority(context)
          authority.with_guard do
            authority.validate_candidate(candidate)
            authority.check_idle_context(context)
            base=candidate.base_lease
            check_state(context,base,base.raw_document,budget)
            old=inspect_base(context.port,base,budget,visits)
            check_state(context,base,base.raw_document,budget)
            authority.consume_candidate(candidate)
            transact(context,candidate,old,budget,visits) { |state| mutation=state }
          end
        end
        result[:metadata][:mutation_state]=mutation
        result
      end
      def check_state(context,base,expected_raw,budget)
        budget.tick('/host/application')
        authority=context.authority
        authority.validate_context(context)
        authority.validate_lease(base,mutation:true)
        authority.check_idle_context(context)
        port=context.port
        fault('E_HOST_EDIT_CONTEXT','/host/edit_path') if port_call { port.edit_path_open? }
        raw=port_call { port.document_json }
        unless (raw.nil? || raw.instance_of?(String)) && raw==expected_raw
          fault('E_HOST_LEASE_CONFLICT','/host/document')
        end
      end
      def manifest(projection)
        {'schema'=>DocumentCodec::MANIFEST_SCHEMA.dup,'plan_sha256'=>projection.plan_sha256,'root_pid_hint'=>nil,
          'parts'=>projection.plan['parts'].map do |part|
            {'part_id'=>part['part_id'],'container_pid_hint'=>nil,'solids'=>part['solids'].map do |s|
              {'component'=>s['component'],'source_index'=>s['source_index'],'pid_hint'=>nil}
            end}
          end}
      end
      def inspect_projection(port,projection,record,budget,visits,staging=nil)
        observed=port_call do
          port.inspect_projection(plan:projection.plan,root_id:record['root_id'],manifest:record['projection'],budget:visits,staging:staging)
        end
        fault('E_HOST_CONTEXT_UNSUPPORTED','/host/inspection') unless observed.instance_of?(Inspection)
        Reader.own_inspection(observed,record,projection,budget)
      end
      def inspect_base(port,base,budget,visits,staging=nil)
        if base.projection.nil?
          observed=port_call { port.inspect_empty(budget:visits) }
          fault('E_HOST_CONTEXT_UNSUPPORTED','/host/inspection') unless observed.instance_of?(Inspection)
          Reader.own_inspection(observed,nil,nil,budget)
        else
          inspect_projection(port,base.projection,base.document,budget,visits,staging)
        end
      end
      def transact(context,candidate,old,budget,visits)
        authority=context.authority;port=context.port;base=candidate.base_lease
        attempted=false;commit_attempted=false;abort_attempted=false;handled=false;complete=false
        begin
          root_id=candidate.projection.plan['parts'].empty? ? nil : (base.document && base.document['root_id']) || Registry.nonce
          acceptance=Registry.nonce
          seed={'root_id'=>root_id,'projection'=>manifest(candidate.projection)}
          attempted=true
          require_true('/host/begin_operation') { port.begin_operation('JP IMOS apply project') }
          check_state(context,base,base.raw_document,budget)
          staged=port_call { port.stage_projection(projection:candidate.projection,root_id:root_id,budget:visits) }
          staged_inspection=inspect_projection(port,candidate.projection,seed,budget,visits,{old_root:old.root_handle,new_root:staged})
          # Reinspect the old root immediately before erasing it. Ignoring the
          # precisely known staged root must not hide a foreign old-root child.
          unless old.root_handle.nil?
            verified=inspect_base(port,base,budget,visits,{old_root:staged,new_root:old.root_handle})
            fault('E_HOST_OWNERSHIP_CONFLICT','/host/old_root') unless verified.root_handle.equal?(old.root_handle)
          end
          check_state(context,base,base.raw_document,budget)
          record=DocumentCodec.record_owned(projection:candidate.projection,root_id:root_id,acceptance_id:acceptance,
            manifest:staged_inspection.manifest || seed['projection'],budget:budget)
          raw=ProjectCore::Codec.encode(record,budget).freeze
          require_true('/host/remove_root') { port.remove_root(old.root_handle) } unless old.root_handle.nil?
          require_true('/host/write_document') { port.write_document(raw) }
          inspect_projection(port,candidate.projection,record,budget,visits)
          check_state(context,base,raw,budget)
          commit_attempted=true
          require_true('/host/commit_operation') { port.commit_operation }
          final=inspect_projection(port,candidate.projection,record,budget,visits)
          check_state(context,base,raw,budget)
          lease=authority.publish_application(context,candidate,raw,record,final)
          complete=true
          yield 'committed'
          lease
        rescue StandardError,Interrupt => error
          cause=error.is_a?(ProjectCore::Fault) ? error : ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/application',nil,{'exception_class'=>error.class.name})
          details={'cause_code'=>cause.code,'cause_pointer'=>cause.json_pointer,'cause'=>cause.diagnostic}
          unless attempted
            handled=true
            raise cause
          end
          if attempted && !commit_attempted
            abort_attempted=true
            begin
              require_true('/host/abort_operation') { port.abort_operation }
              verify_restoration(context,base,budget,visits)
              authority.before_action!
              handled=true
              yield 'rolled_back'
              fault('E_HOST_APPLY_FAILED','/host/application',details)
            rescue ProjectCore::Fault => restoration_error
              # Our deliberate rolled_back diagnostic must escape this nested
              # cleanup handler, rather than being mistaken for abort failure.
              raise if handled
              details['rollback_code']=restoration_error.code
              details['rollback_pointer']=restoration_error.json_pointer
              details['rollback']=restoration_error.diagnostic
            end
          end
          authority.quarantine!
          handled=true
          yield 'unknown'
          fault('E_HOST_COMMIT_INDETERMINATE','/host/application',details)
        ensure
          # Fatal exceptions are re-raised. Best-effort cleanup never masks
          # them, retries abort, or attempts compensation after commit.
          if attempted && !complete && !handled
            begin
              port.abort_operation unless commit_attempted || abort_attempted
            rescue Exception
              nil
            end
            begin
              authority.quarantine!
            rescue Exception
              nil
            end
          end
        end
      end
      def verify_restoration(context,base,budget,visits)
        authority=context.authority;port=context.port
        authority.validate_context(context)
        budget.tick('/host/restoration')
        stable=port_call { port.document_json==base.raw_document && !port.edit_path_open? }
        fault('E_HOST_LEASE_CONFLICT','/host/restoration/document') unless stable
        inspect_base(port,base,budget,visits)
        stable=port_call { port.document_json==base.raw_document && !port.edit_path_open? && port.anchor.equal?(authority.anchor) }
        fault('E_HOST_LEASE_CONFLICT','/host/restoration/document') unless stable
      end
    end
  end
end
