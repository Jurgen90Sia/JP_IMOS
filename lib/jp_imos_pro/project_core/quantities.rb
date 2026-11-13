# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    module Quantities
      module_function
      def validate(value, pointer, budget)
        budget.tick(pointer)
        raise Fault.new('E_INPUT_CONTRACT',pointer) unless value.instance_of?(Hash)
        type = value['type']
        keys = case type
        when 'Length' then %w[type unit numeric]
        when 'Scalar' then %w[type numeric]
        when 'Boolean' then %w[type value]
        else raise Fault.new('E_INPUT_CONTRACT',pointer)
        end
        unless value.size == keys.size && keys.all? { |key| value.key?(key) }
          raise Fault.new('E_INPUT_CONTRACT',pointer)
        end
        dto = {type: type}
        if type == 'Boolean'
          dto[:value] = value['value']
        else
          data = value['numeric']
          unless data.instance_of?(Hash) && data.size == 3 && %w[numerator denominator exact].all? { |key| data.key?(key) }
            raise Fault.new('E_INPUT_CONTRACT',ProjectCore.pointer(pointer,'numeric'))
          end
          dto[:numeric] = {numerator:data['numerator'],denominator:data['denominator'],exact:data['exact']}
          dto[:unit] = value['unit'] if type == 'Length'
        end
        Parametric::Value.deserialize(dto,Parametric::Budget.new({}),pointer)
        result = {}
        keys.each do |key|
          result[key] = key == 'numeric' ? %w[numerator denominator exact].each_with_object({}) { |k,h| h[k] = value[key][k] } : value[key]
        end
        result
      rescue Parametric::Fault => e
        raise Fault.new(e.code,pointer,nil,{input_path: e.path})
      end
    end
  end
end
