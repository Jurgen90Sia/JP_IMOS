# frozen_string_literal: true
require_relative '../design/physical_checkpoint'

module JPImosPro
  module Host
    class PreparedProjection
      attr_reader :state,:snapshot,:checkpoint_record,:plan,:plan_sha256
      def initialize(state,snapshot,checkpoint_record,plan,plan_sha256)
        @state,@snapshot,@checkpoint_record,@plan,@plan_sha256=state,snapshot,checkpoint_record,plan,plan_sha256
        freeze
      end
      private_class_method :new
    end

    module Projection
      SCHEMA='jpimos.host-projection/1'
      PROFILE='jp-host-unbanded-scratch-v1'
      MIN_EXTENT=Rational(1,10)
      MAX_COORDINATE=1_000_000
      module_function

      def build(state:,numeric_policy:,limits: {})
        result=ProjectCore.boundary(limits) do |budget|
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          owned,snapshot,_=Design::PhysicalCheckpoint.fresh(state,policy,budget)
          from_owned_resolution(state:owned,snapshot:snapshot,numeric_policy:policy,budget:budget)
        end
        result[:metadata]={schema:SCHEMA,profile_version:PROFILE,mutation_state:'unchanged'}
        result
      end

      # Internal reuse of a source resolution, never a public snapshot importer.
      # All data must be owned/frozen and rebuilt by this core in this request.
      def from_owned_resolution(state:,snapshot:,numeric_policy:,budget:)
        checkpoint=Design::PhysicalCheckpoint.record_from_owned_resolution(
          state:state,snapshot:snapshot,numeric_policy:numeric_policy,budget:budget)
        origins={}
        snapshot['design_snapshot']['carcass_previews'].each do |preview|
          budget.tick('/projection/origins')
          origins[preview['source_context']['article_instance_id']]=preview['article_origin'].map { |v| Zones::EngineBridge.rational(v) }
        end
        parts=snapshot['parts'].each_with_index.map do |entry,i|
          budget.tick('/projection/parts')
          part=entry['part'];origin=origins.fetch(part['occurrence_ref']['article_instance_id'])
          solids=[solid(part['substrate_geometry'],origin,'substrate',nil,budget,"/parts/#{i}/solids/0")]
          part['surface_layers'].each do |layer|
            solids << solid(layer['geometry'],origin,'surface',layer['source_index'],budget,"/parts/#{i}/solids/#{solids.size}")
          end
          {'part_id'=>part['id'],'solids'=>solids}
        end
        plan={'schema'=>SCHEMA.dup,'profile'=>PROFILE.dup,'project_id'=>snapshot['project_id'],
          'source_revision'=>snapshot['source_revision'],'state_sha256'=>snapshot['state_sha256'],
          'catalog_sha256'=>snapshot['catalog_sha256'],'policy_id'=>numeric_policy[:policy_id],
          'backend_id'=>numeric_policy[:backend_id],'parts'=>parts}
        validator=ProjectCore::Document.new(budget)
        plan=validator.deep_freeze(validator.copy(plan))
        digest=Design::PhysicalSnapshot.digest(plan,budget).freeze
        PreparedProjection.send(:new,state,snapshot,checkpoint,plan,digest)
      end

      def solid(geometry,origin,component,source_index,budget,path)
        spec=geometry['solid_spec']
        extents=[spec['outer_loop'][1][0],spec['outer_loop'][2][1],spec['thickness']]
        extents.each do |value|
          budget.tick(path)
          unrepresentable(path) if Zones::EngineBridge.rational(value)<MIN_EXTENT
        end
        # article_vertices already contain the part frame. Only article origin
        # remains to reach model coordinates; applying the basis twice is wrong.
        vertices=geometry['article_vertices'].map do |point|
          point.each_with_index.map do |value,axis|
            world=Zones::Frame.safe(Zones::EngineBridge.rational(value)+origin[axis],budget)
            unrepresentable(path) if world.abs>MAX_COORDINATE || !world.to_f.finite?
            Zones::EngineBridge.length(world)
          end
        end
        {'component'=>component,'source_index'=>source_index,'world_vertices'=>vertices,
          'face_loops'=>geometry['face_loops'],'expected_volume'=>geometry['finished_envelope_volume']}
      end
      def unrepresentable(path)
        raise ProjectCore::Fault.new('E_HOST_GEOMETRY_UNREPRESENTABLE',path)
      end
    end
  end
end
