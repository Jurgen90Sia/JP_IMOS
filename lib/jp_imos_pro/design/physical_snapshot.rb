# frozen_string_literal: true
module JPImosPro
  module Design
    module PhysicalSnapshot
      module_function
      def digest(value,budget)
        ordered=ProjectCore::Document.new(budget).copy(value)
        Digest::SHA256.hexdigest(ProjectCore::Codec.encode(ordered,budget))
      end
      def build(state,report,policy,budget)
        design=state['design']
        derived=PhysicalRecord.scoped('/design') { Snapshot.build(design,policy,budget) }
        state_sha=digest(state,budget)
        project=design['project']
        binding={'project_id'=>project['project_id'],'source_revision'=>project['revision'],
          'state_sha256'=>state_sha,'catalog_sha256'=>report['catalog_sha256']}
        policies=state['part_policies'].each_with_object({}) do |value,index|
          budget.tick('/part_policies');index[[value['article_instance_id'],value['role']]]=value
        end
        requests=design['construction_requests'].each_with_object({}) do |value,index|
          budget.tick('/design/construction_requests');index[value['article_instance_id']]=value
        end
        parts=[]
        derived['carcass_previews'].each do |preview|
          preview['panels'].each do |panel|
            occurrence=panel['occurrence_ref'];role=panel['role']
            identity=policies.fetch([occurrence['article_instance_id'],role])
            intent={'schema'=>Physical::RectangularPart::INTENT_SCHEMA.dup,'id'=>identity['id'],
              'occurrence_ref'=>occurrence,'owner_zone_ref'=>panel['owner_zone_ref'],'rule_version'=>panel['rule_version'],
              'face_size'=>panel['face_size'],'frame'=>panel['frame'],
              'characteristic'=>requests.fetch(occurrence['article_instance_id'])['panels'][role],
              'grain'=>identity['grain'],'edges'=>identity['edges']}
            begin
              part=Physical::RectangularPart.build_owned(intent,budget)
            rescue ProjectCore::Fault => e
              raise ProjectCore::Fault.new(e.code,"/parts/#{parts.size}"+e.json_pointer,e.entity_ref,e.details,e.engine)
            end
            parts << {'source_binding'=>binding,'part'=>part}
          end
        end
        payload={'schema'=>'jpimos.physical-design-snapshot/1','profile_version'=>PhysicalState::PROFILE.dup,
          'status'=>'prepared_registry_bound_user_declared','project_id'=>project['project_id'],
          'source_revision'=>project['revision'],'state_sha256'=>state_sha,'catalog_sha256'=>report['catalog_sha256'],
          'design_snapshot'=>derived,'material_report'=>report,'material_report_state_scope'=>'design',
          'parts'=>parts,'diagnostics'=>[]}
        validator=ProjectCore::Document.new(budget)
        output=validator.copy(payload)
        output['content_sha256']=Digest::SHA256.hexdigest(ProjectCore::Codec.encode(output,budget))
        validator.deep_freeze(output)
      end
    end
  end
end
