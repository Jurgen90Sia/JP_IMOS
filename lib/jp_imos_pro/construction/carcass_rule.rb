# frozen_string_literal: true
module JPImosPro
  module Construction
    module CarcassRule
      module_function
      def lengths(values)
        values.map { |n| Zones::EngineBridge.length(n) }
      end
      def build(article:,contexts:,budget:)
        width,depth,height=article['reference_extents'].map { |v| Zones::EngineBridge.rational(v) }
        thicknesses=Request::ROLES.map { |role| Zones::EngineBridge.rational(contexts.fetch(role)['finished_stack_thickness']) }
        left,right,top,bottom=thicknesses
        cw=Zones::Frame.safe(Zones::Frame.safe(width-left,budget)-right,budget)
        ch=Zones::Frame.safe(Zones::Frame.safe(height-top,budget)-bottom,budget)
        unless cw>0 && ch>0
          raise ProjectCore::Fault.new('E_INFEASIBLE_CONSTRUCTION','/request/panels')
        end
        origins=[[0,0,0],[width,depth,0],[left,depth,height],[left,0,0]]
        bases=[[[0,1,0],[0,0,1],[1,0,0]],[[0,-1,0],[0,0,1],[-1,0,0]],
          [[1,0,0],[0,-1,0],[0,0,-1]],[[1,0,0],[0,1,0],[0,0,1]]]
        faces=[[depth,height],[depth,height],[cw,depth],[cw,depth]]
        recipes=Request::ROLES.each_with_index.map do |role,i|
          budget.tick('/request/panels/'+role)
          {'occurrence_ref'=>{'article_instance_id'=>article['article_instance_id'],'role'=>role},
            'owner_zone_ref'=>article['root_occurrence_ref'],'rule_version'=>Request::PRINCIPLE.dup,
            'role'=>role,'kind'=>'rectangular_panel','characteristic'=>contexts.fetch(role),
            'face_size'=>lengths(faces[i]),'finished_thickness'=>Zones::EngineBridge.length(thicknesses[i]),
            'frame'=>{'origin'=>lengths(origins[i]),'basis'=>bases[i]}}
        end
        result={'reference_envelope'=>{'origin'=>lengths([0,0,0]),'extents'=>lengths([width,depth,height])},
          'reference_opening'=>{'origin'=>lengths([left,0,bottom]),'extents'=>lengths([cw,depth,ch])},'recipes'=>recipes}
        ProjectCore::Document.new(budget).deep_freeze(result)
      end
    end
  end
end
