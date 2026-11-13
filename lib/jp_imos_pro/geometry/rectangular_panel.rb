# frozen_string_literal: true
module JPImosPro
  module Geometry
    module RectangularPanel
      FACES={'n_min'=>[0,3,2,1],'n_max'=>[4,5,6,7],'v_min'=>[0,1,5,4],
        'u_max'=>[1,2,6,5],'v_max'=>[2,3,7,6],'u_min'=>[3,0,4,7]}.each_value(&:freeze).freeze
      RECIPE_KEYS=%w[occurrence_ref owner_zone_ref rule_version role kind characteristic face_size finished_thickness frame].freeze
      module_function
      def coordinate(value,budget)
        v=ProjectCore::Quantities.validate(value,'/geometry/frame',budget)
        raise ProjectCore::Fault.new('E_UNIT_MISMATCH','/geometry/frame') unless v['type']=='Length'
        raise ProjectCore::Fault.new('E_INEXACT_DIVISION_INPUT','/geometry/frame') unless v['numeric']['exact']
        Zones::EngineBridge.rational(v)
      end
      def lengths(values)
        values.map { |n| Zones::EngineBridge.length(n) }
      end
      def from_recipe(recipe:,budget:)
        unless recipe.instance_of?(Hash) && recipe.size==RECIPE_KEYS.size && RECIPE_KEYS.all? { |k| recipe.key?(k) }
          raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/geometry')
        end
        raise ProjectCore::Fault.new('E_CONSTRUCTION_UNSUPPORTED','/geometry/kind') unless recipe['kind']=='rectangular_panel'
        unless recipe['face_size'].instance_of?(Array) && recipe['face_size'].size==2
          raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/geometry/face_size')
        end
        extents=(recipe['face_size']+[recipe['finished_thickness']]).map { |v| coordinate(v,budget) }
        raw=recipe['frame']
        unless raw.instance_of?(Hash) && raw.size==2 && raw.key?('origin') && raw.key?('basis') && raw['origin'].instance_of?(Array) && raw['origin'].size==3
          raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/geometry/frame')
        end
        frame={origin:raw['origin'].map { |v| coordinate(v,budget) },basis:raw['basis'],extents:extents}
        begin
          Zones::Frame.validate(frame,budget)
        rescue ProjectCore::Fault => e
          raise if e.code=='E_RESOURCE_LIMIT'
          raise ProjectCore::Fault.new('E_INVALID_GEOMETRY','/geometry/frame')
        end
        u,v,t=extents
        local=[[0,0,0],[u,0,0],[u,v,0],[0,v,0],[0,0,t],[u,0,t],[u,v,t],[0,v,t]]
        vertices=local.map { |point| Zones::Frame.map_point(frame:frame,point:point,budget:budget) }
        min=3.times.map { |i| vertices.map { |point| point[i] }.min }
        max=3.times.map { |i| vertices.map { |point| point[i] }.max }
        volume=Zones::Frame.safe(Zones::Frame.safe(u*v,budget)*t,budget)
        frame_dto={'origin'=>lengths(frame[:origin]),'basis'=>frame[:basis].map(&:dup)}
        result={'solid_spec'=>{'schema'=>'jpimos.rectangular-solid/1','kind'=>'extruded_contour',
            'outer_loop'=>[[0,0],[u,0],[u,v],[0,v]].map { |point| lengths(point) },'holes'=>[],
            'thickness'=>Zones::EngineBridge.length(t),'frame'=>frame_dto},
          'article_vertices'=>vertices.map { |point| lengths(point) },'face_loops'=>FACES.transform_values(&:dup),
          'bbox_min'=>lengths(min),'bbox_max'=>lengths(max),
          'finished_envelope_volume'=>{'unit'=>'mm3','numeric'=>{'numerator'=>volume.numerator.to_s,'denominator'=>volume.denominator.to_s,'exact'=>true}}}
        ProjectCore::Document.new(budget).deep_freeze(result)
      end
    end
  end
end
