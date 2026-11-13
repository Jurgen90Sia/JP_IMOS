# frozen_string_literal: true
require_relative '../construction'

module JPImosPro
  module Physical
    module RectangularPart
      INTENT_SCHEMA='jpimos.rectangular-part-intent/1'
      SCHEMA='jpimos.rectangular-physical-part/1'
      PROFILE='jp-rectangular-unbanded-v1'
      KEYS=%w[schema id occurrence_ref owner_zone_ref rule_version face_size frame characteristic grain edges].freeze
      SEGMENTS=%w[u_min u_max v_min v_max].freeze
      GRAIN=%w[none u v].freeze
      module_function

      def validate_identity(data,budget)
        validator=ProjectCore::Document.new(budget)
        validator.check(data['id'],:uuid,'/intent/id')
        occurrence=data['occurrence_ref']
        Materials::Context.keys(occurrence,%w[article_instance_id role],'/intent/occurrence_ref')
        validator.check(occurrence['article_instance_id'],:uuid,'/intent/occurrence_ref/article_instance_id')
        unless Construction::Request::ROLES.include?(occurrence['role'])
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/intent/occurrence_ref/role')
        end
        owner=data['owner_zone_ref']
        Materials::Context.keys(owner,%w[article_instance_id authored_zone_id],'/intent/owner_zone_ref')
        %w[article_instance_id authored_zone_id].each { |key| validator.check(owner[key],:uuid,'/intent/owner_zone_ref/'+key) }
        unless owner['article_instance_id']==occurrence['article_instance_id']
          raise ProjectCore::Fault.new('E_REFERENCE_MISMATCH','/intent/owner_zone_ref/article_instance_id')
        end
        unless data['rule_version']==Construction::Request::PRINCIPLE
          raise ProjectCore::Fault.new('E_PART_PROFILE_UNSUPPORTED','/intent/rule_version')
        end
      end

      def validate_policies(data,context,budget)
        grain=data['grain']
        Materials::Context.keys(grain,%w[substrate surfaces],'/intent/grain')
        unless GRAIN.include?(grain['substrate'])
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/intent/grain/substrate')
        end
        values=grain['surfaces']
        unless values.instance_of?(Array) && values.size==context['dimensional_surfaces'].size
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/intent/grain/surfaces')
        end
        values.each_with_index do |value,i|
          budget.tick('/intent/grain/surfaces')
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',"/intent/grain/surfaces/#{i}") unless GRAIN.include?(value)
        end
        Materials::Context.keys(data['edges'],SEGMENTS,'/intent/edges')
        SEGMENTS.each do |segment|
          path='/intent/edges/'+segment
          edge=data['edges'][segment]
          unless edge.instance_of?(Hash) && edge.key?('kind')
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path)
          end
          unless edge['kind']=='none'
            raise ProjectCore::Fault.new('E_PART_PROFILE_UNSUPPORTED',path+'/kind')
          end
          Materials::Context.keys(edge,%w[kind],path)
        end
      end

      def shifted_frame(frame,offset,budget)
        origin=frame['origin'].map { |value| Geometry::RectangularPanel.coordinate(value,budget) }
        normal=frame['basis'][2]
        shifted=3.times.map { |i| Zones::Frame.safe(origin[i]+Zones::Frame.safe(normal[i]*offset,budget),budget) }
        {'origin'=>shifted.map { |value| Zones::EngineBridge.length(value) },'basis'=>frame['basis']}
      end

      # Internal composition uses only the already owned and validated intent.
      def geometry(recipe,thickness,offset,budget)
        part=recipe.merge('finished_thickness'=>thickness,'frame'=>shifted_frame(recipe['frame'],offset,budget))
        Geometry::RectangularPanel.from_recipe(recipe:part,budget:budget)
      end

      def build(intent:,limits: {})
        result=ProjectCore.boundary(limits) do |budget|
          data=Materials::Context.copy(intent,budget,'/intent')
          unless data.instance_of?(Hash)
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT','/intent')
          end
          if data.key?('schema') && data['schema']!=INTENT_SCHEMA
            raise ProjectCore::Fault.new('E_SCHEMA_UNSUPPORTED','/intent/schema')
          end
          Materials::Context.keys(data,KEYS,'/intent')
          validate_identity(data,budget)
          context=Materials::Context.resolve(characteristic:data['characteristic'],budget:budget,pointer:'/intent/characteristic')
          validate_policies(data,context,budget)
          recipe={'occurrence_ref'=>data['occurrence_ref'],'owner_zone_ref'=>data['owner_zone_ref'],
            'rule_version'=>data['rule_version'],'role'=>data['occurrence_ref']['role'],'kind'=>'rectangular_panel',
            'characteristic'=>context,'face_size'=>data['face_size'],'finished_thickness'=>context['finished_stack_thickness'],
            'frame'=>data['frame']}
          # Validate the complete finished frame before using its normal column.
          finished=Geometry::RectangularPanel.from_recipe(recipe:recipe,budget:budget)
          near=Zones::EngineBridge.rational(context['near_surface_thickness'])
          substrate_t=context['finished_substrate_thickness']
          substrate=geometry(recipe,substrate_t,near,budget)
          cursors={'near'=>0.to_r,'far'=>Zones::Frame.safe(near+Zones::EngineBridge.rational(substrate_t),budget)}
          layers=context['dimensional_surfaces'].each_with_index.map do |layer,i|
            budget.tick('/intent/characteristic/dimensional_surfaces')
            side=layer['side']
            solid=geometry(recipe,layer['finished_thickness'],cursors.fetch(side),budget)
            cursors[side]=Zones::Frame.safe(cursors[side]+Zones::EngineBridge.rational(layer['finished_thickness']),budget)
            {'source_index'=>i,'side'=>side,'material_ref'=>layer['material_ref'],
              'grain'=>data['grain']['surfaces'][i],'geometry'=>solid}
          end
          payload={'schema'=>SCHEMA.dup,'profile_version'=>PROFILE.dup,'status'=>'prepared_unbound_part',
            'id'=>data['id'],'occurrence_ref'=>data['occurrence_ref'],'owner_zone_ref'=>data['owner_zone_ref'],
            'rule_version'=>data['rule_version'],'characteristic'=>context,'grain'=>data['grain'],'edges'=>data['edges'],
            'finished_dimensions'=>data['face_size']+[context['finished_stack_thickness']],
            'substrate_dimensions'=>data['face_size']+[substrate_t],
            'finished_geometry'=>finished,'substrate_geometry'=>substrate,'surface_layers'=>layers,
            'actual_volume'=>finished['finished_envelope_volume']}
          validator=ProjectCore::Document.new(budget)
          output=validator.copy(payload)
          output['content_sha256']=Digest::SHA256.hexdigest(ProjectCore::Codec.encode(output,budget))
          validator.deep_freeze(output)
        end
        result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
        result
      end
    end
  end
end
