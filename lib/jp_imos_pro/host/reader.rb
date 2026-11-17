# frozen_string_literal: true
require_relative 'lease'
module JPImosPro
  module Host
    module Reader
      module_function
      def read(context:,numeric_policy:,limits: {})
        Registry.boundary(limits) do |budget,visits|
          authority=Registry.context_authority(context)
          authority.with_guard do
            grant=authority.port_call { context.port.controlled_grant }
            inspect_with_budget(context,numeric_policy,budget,visits,false,grant)
          end
        end
      end
      def inspect_with_budget(context,numeric_policy,budget,visits,recovery,grant)
        authority=Registry.context_authority(context);port=context.port
        ticket=authority.begin_read(context,grant)
        policy=ProjectCore::Document.new(budget).deep_freeze(ProjectCore.validated_policy(numeric_policy,budget))
        raise ProjectCore::Fault.new('E_HOST_EDIT_CONTEXT','/host/edit_path') if authority.port_call { port.edit_path_open? }
        raw=authority.port_call { port.document_json }
        unless raw.nil? || raw.instance_of?(String)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/host/document')
        end
        unless raw.nil?
          budget.cap(raw.bytesize,:json_bytes,'/host/document')
          raw=raw.dup.freeze
        end
        if raw.nil?
          document=nil;projection=nil
          inspection=authority.port_call { port.inspect_empty(budget:visits) }
        else
          decoded=DocumentCodec.decode_with_budget(source:raw,numeric_policy:policy,budget:budget)
          document=decoded.document;projection=decoded.projection
          inspection=authority.port_call { port.inspect_projection(plan:projection.plan,root_id:document['root_id'],manifest:document['projection'],budget:visits) }
        end
        stable=authority.port_call { port.document_json==raw && !port.edit_path_open? && port.anchor.equal?(authority.anchor) }
        unless stable
          authority.quarantine!
          raise ProjectCore::Fault.new('E_HOST_LEASE_CONFLICT','/host/document')
        end
        unless inspection.instance_of?(Inspection)
          raise ProjectCore::Fault.new('E_HOST_CONTEXT_UNSUPPORTED','/host/inspection')
        end
        inspection=own_inspection(inspection,document,projection,budget)
        authority.publish_lease(context,ticket,raw,document,projection,inspection,policy,recovery)
      end
      def own_inspection(inspection,document,projection,budget)
        if document.nil?
          DocumentCodec.ownership('/host/inspection') unless inspection.root_handle.nil? && inspection.manifest.nil?
          return Inspection.send(:new,nil,nil)
        end
        empty=projection.plan['parts'].empty?
        DocumentCodec.ownership('/host/inspection/root') unless inspection.root_handle.nil? == empty
        raw=inspection.manifest
        raw=document['projection'] if raw.nil? && empty
        validator=ProjectCore::Document.new(budget)
        mapping=validator.copy(raw)
        DocumentCodec.validate_manifest(mapping,projection,budget)
        DocumentCodec.ownership('/host/inspection/root_pid_hint') if empty && !mapping['root_pid_hint'].nil?
        Inspection.send(:new,inspection.root_handle,validator.deep_freeze(mapping))
      end
    end
  end
end
