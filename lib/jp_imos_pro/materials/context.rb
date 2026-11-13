# frozen_string_literal: true
module JPImosPro
  module Materials
    module Context
      POLICY='additive_finished_stack-v1'
      module_function
      def copy(value,budget,pointer)
        ProjectCore::Document.new(budget).copy(value)
      rescue ProjectCore::Fault => e
        raise ProjectCore::Fault.new(e.code,pointer+e.json_pointer,e.entity_ref,e.details,e.engine)
      end
      def keys(value,required,pointer)
        unless value.instance_of?(Hash)
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',pointer)
        end
        errors=(value.keys-required)+(required-value.keys)
        unless errors.empty?
          path=errors.map { |key| ProjectCore.pointer(pointer,key) }.min
          raise ProjectCore::Fault.new('E_INPUT_CONTRACT',path)
        end
      end
      def material(value,budget,pointer)
        keys(value,%w[id version],pointer)
        validator=ProjectCore::Document.new(budget)
        {'id'=>validator.check(value['id'],:uuid,pointer+'/id'),'version'=>validator.check(value['version'],:version,pointer+'/version')}
      end
      def thickness(value,budget,pointer)
        v=ProjectCore::Quantities.validate(value,pointer,budget)
        raise ProjectCore::Fault.new('E_UNIT_MISMATCH',pointer) unless v['type']=='Length'
        raise ProjectCore::Fault.new('E_INEXACT_DIVISION_INPUT',pointer) unless v['numeric']['exact']
        raise ProjectCore::Fault.new('E_DOMAIN',pointer) unless Zones::EngineBridge.rational(v)>0
        v
      end
      def validate_input(value,budget,pointer)
        keys(value,%w[policy material_ref nominal_purchase_thickness finished_substrate_thickness dimensional_surfaces],pointer)
        unless value['policy']==POLICY
          raise ProjectCore::Fault.new('E_CONSTRUCTION_UNSUPPORTED',pointer+'/policy')
        end
        surfaces=value['dimensional_surfaces']
        raise ProjectCore::Fault.new('E_INPUT_CONTRACT',pointer+'/dimensional_surfaces') unless surfaces.instance_of?(Array)
        raise ProjectCore::Fault.new('E_RESOURCE_LIMIT',pointer+'/dimensional_surfaces') if surfaces.size>16
        layers=surfaces.each_with_index.map do |layer,i|
          p="#{pointer}/dimensional_surfaces/#{i}"
          budget.tick(p)
          keys(layer,%w[side material_ref finished_thickness],p)
          unless %w[near far].include?(layer['side'])
            raise ProjectCore::Fault.new('E_INPUT_CONTRACT',p+'/side')
          end
          {'side'=>layer['side'],'material_ref'=>material(layer['material_ref'],budget,p+'/material_ref'),
            'finished_thickness'=>thickness(layer['finished_thickness'],budget,p+'/finished_thickness')}
        end
        {'policy'=>POLICY.dup,'material_ref'=>material(value['material_ref'],budget,pointer+'/material_ref'),
          'nominal_purchase_thickness'=>thickness(value['nominal_purchase_thickness'],budget,pointer+'/nominal_purchase_thickness'),
          'finished_substrate_thickness'=>thickness(value['finished_substrate_thickness'],budget,pointer+'/finished_substrate_thickness'),
          'dimensional_surfaces'=>layers}
      end
      def resolve(characteristic:,budget:,pointer:)
        input=validate_input(copy(characteristic,budget,pointer),budget,pointer)
        near,far=0.to_r,0.to_r
        input['dimensional_surfaces'].each do |layer|
          t=Zones::EngineBridge.rational(layer['finished_thickness'])
          if layer['side']=='near'
            near=Zones::Frame.safe(near+t,budget)
          else
            far=Zones::Frame.safe(far+t,budget)
          end
        end
        substrate=Zones::EngineBridge.rational(input['finished_substrate_thickness'])
        total=Zones::Frame.safe(Zones::Frame.safe(substrate+near,budget)+far,budget)
        result=input.merge('near_surface_thickness'=>Zones::EngineBridge.length(near),
          'far_surface_thickness'=>Zones::EngineBridge.length(far),'finished_stack_thickness'=>Zones::EngineBridge.length(total),
          'material_reference_status'=>'caller_declared_unverified_catalog')
        ProjectCore::Document.new(budget).deep_freeze(result)
      end
    end
  end
end
