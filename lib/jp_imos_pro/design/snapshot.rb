# frozen_string_literal: true
module JPImosPro
  module Design
    module Snapshot
      module_function
      def build(state,policy,budget)
        project=state['project']
        begin
          zones=Zones::Resolver.resolve(validated_document:project,policy:policy,budget:budget)
          project_sha=Digest::SHA256.hexdigest(ProjectCore::Codec.encode(project,budget))
        rescue ProjectCore::Fault => e
          raise ProjectCore::Fault.new(e.code,'/project'+e.json_pointer,e.entity_ref,e.details,e.engine)
        end
        previews=state['construction_requests'].each_with_index.map do |request,i|
          budget.tick('/construction_requests')
          begin
            Construction.preview_from_validated(document:project,request:request,zone_snapshot:zones,
              project_sha:project_sha,policy:policy,budget:budget)
          rescue ProjectCore::Fault => e
            path=e.json_pointer.start_with?('/request') ? e.json_pointer.delete_prefix('/request') : e.json_pointer
            raise ProjectCore::Fault.new(e.code,"/construction_requests/#{i}"+path,e.entity_ref,e.details,e.engine)
          end
        end
        snapshot={'schema'=>'jpimos.carcass-design-snapshot/1','profile_version'=>PROFILE.dup,'project_id'=>project['project_id'],
          'source_revision'=>project['revision'],'state_sha256'=>Digest::SHA256.hexdigest(ProjectCore::Codec.encode(state,budget)),
          'policy_id'=>policy[:policy_id].dup,'backend_id'=>policy[:backend_id].dup,'zone_snapshot'=>zones,
          'carcass_previews'=>previews,'diagnostics'=>[]}
        ProjectCore::Document.new(budget).deep_freeze(snapshot)
      end
    end
  end
end
