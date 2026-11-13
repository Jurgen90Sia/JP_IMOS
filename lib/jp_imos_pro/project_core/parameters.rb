# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    module Parameters
      RESERVED = %w[pi true false X Y abs min max if sin cos tan asin acos ZONE_U ZONE_V ZONE_W].freeze
      module_function
      def validate_all(document,budget)
        document['definitions'].each_with_index do |definition,i|
          validate_definition(definition,"/definitions/#{i}",budget)
        end
        document['articles'].each_with_index do |instance,i|
          budget.tick("/articles/#{i}")
          ref = instance['definition_ref']
          definition = document['definitions'].find { |d| d['id']==ref['id'] && d['version']==ref['version'] }
          bind(instance,definition,"/articles/#{i}",budget) if definition
          instance['origin'].each_with_index { |v,j| exact!(v,"/articles/#{i}/origin/#{j}") }
        end
      end
      def exact!(value,pointer)
        if value['type'] != 'Boolean' && !value['numeric']['exact']
          raise Fault.new('E_INEXACT_DIVISION_INPUT',pointer)
        end
      end
      def validate_definition(definition,pointer,budget)
        names = {}
        definition['parameters'].each_with_index do |parameter,i|
          path = "#{pointer}/parameters/#{i}"
          budget.tick(path)
          name = parameter['name']
          unless name.ascii_only? && /\A[A-Za-z_][A-Za-z0-9_]*\z/.match?(name)
            raise Fault.new('E_INPUT_CONTRACT',path+'/name')
          end
          raise Fault.new('E_DUPLICATE_ID',path+'/name') if names.key?(name)
          raise Fault.new('E_RESERVED_SYMBOL',path+'/name') if RESERVED.include?(name)
          names[name] = parameter
          type = parameter['expected_type']
          raise Fault.new('E_TYPE_UNSUPPORTED',path+'/expected_type') unless %w[Scalar Length Boolean].include?(type)
          default = parameter['default_value']
          raise Fault.new('E_INPUT_CONTRACT',path+'/default_value') if parameter['required'] && !default.nil?
          if default
            raise Fault.new('E_UNIT_MISMATCH',path+'/default_value') unless default['type'] == type
            exact!(default,path+'/default_value')
          end
        end
        %w[D H W].each do |name|
          p = names[name]
          raise Fault.new('E_PARAMETER_REQUIRED',pointer+'/parameters',nil,{parameter:name}) unless p
          unless p['expected_type']=='Length' && p['required'] && p['default_value'].nil?
            raise Fault.new('E_INPUT_CONTRACT',pointer+'/parameters',nil,{parameter:name})
          end
        end
        names
      end
      def bind(instance,definition,pointer,budget)
        declared = definition['parameters'].each_with_object({}) { |p,h| h[p['name']]=p }
        values = instance['parameter_values']
        unknown = values.keys - declared.keys
        unless unknown.empty?
          raise Fault.new('E_PARAMETER_UNKNOWN',ProjectCore.pointer(pointer+'/parameter_values',unknown.min))
        end
        declared.keys.sort.each_with_object({}) do |name, result|
          path = ProjectCore.pointer(pointer+'/parameter_values',name)
          budget.tick(path)
          parameter = declared[name]
          if values.key?(name)
            value = values[name]
          elsif !parameter['required'] && !parameter['default_value'].nil?
            value = parameter['default_value']
          else
            raise Fault.new('E_PARAMETER_REQUIRED',path)
          end
          raise Fault.new('E_UNIT_MISMATCH',path) unless value['type']==parameter['expected_type']
          exact!(value,path)
          if %w[W H D].include?(name) && value['numeric']['numerator'].to_i <= 0
            raise Fault.new('E_DOMAIN',path)
          end
          result[name]=value
        end
      end
    end
  end
end
