# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    class Document
      SAFE_INTEGER = 9_007_199_254_740_991
      UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
      def self.validate(raw,budget)
        new(budget).validate(raw)
      end
      def self.validate_owned(raw,budget)
        new(budget).validate_owned(raw)
      end
      def initialize(budget)
        @budget = budget
      end
      def fail_at(path, code = 'E_INPUT_CONTRACT')
        raise Fault.new(code,path)
      end
      def validate(raw)
        validate_owned(copy(raw))
      end
      # Trusted callers have already completed the bounded plain-data copy.
      def validate_owned(data)
        fail_at('') unless data.instance_of?(Hash)
        fail_at('/schema','E_SCHEMA_UNSUPPORTED') if data.key?('schema') && data['schema'] != SCHEMA
        result = record(data,{
          'schema'=>[:enum,[SCHEMA]],'project_id'=>:uuid,'revision'=>:revision,
          'locale'=>[:enum,%w[sq en]],'units'=>[:enum,['mm']],
          'definitions'=>[:array,:definition,:definitions], 'articles'=>[:array,:article,:articles]},'')
        index = References.validate(result,@budget)
        Parameters.validate_all(result,@budget,index)
        deep_freeze(result)
      end
      def copy(raw)
        holder, active = [], {}
        stack = [[:enter,raw,holder,0,'',0]]
        until stack.empty?
          action, value, target, key, path, depth = stack.pop
          if action == :leave
            active.delete(value.object_id)
            next
          end
          @budget.tick(path)
          if value.instance_of?(Hash) || value.instance_of?(Array)
            fail_at(path) if active.key?(value.object_id)
            @budget.cap(depth+1,:json_depth,path)
            @budget.tick(path,value.size)
            active[value.object_id] = true
            stack << [:leave,value]
            output = value.instance_of?(Hash) ? {} : Array.new(value.size)
            target[key] = output
            if value.instance_of?(Hash)
              value.each_key do |name|
                fail_at(path) unless text?(name)
                @budget.text_bytes(name.bytesize,path)
              end
              value.keys.sort_by { |name| ProjectCore.pointer(path,name) }.reverse_each { |name| stack << [:enter,value[name],output,name.dup,ProjectCore.pointer(path,name),depth+1] }
            else
              (0...value.size).sort_by { |i| i.to_s }.reverse_each { |i| stack << [:enter,value[i],output,i,ProjectCore.pointer(path,i),depth+1] }
            end
          elsif value.instance_of?(String)
            fail_at(path) unless text?(value)
            @budget.cap(value.bytesize,:json_bytes,path)
            @budget.text_bytes(value.bytesize,path)
            target[key] = value.dup
          elsif value.instance_of?(Integer)
            fail_at(path) if value.abs > SAFE_INTEGER
            target[key] = value
          elsif value.instance_of?(NilClass) || value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
            target[key] = value
          else
            fail_at(path)
          end
        end
        holder[0]
      end
      def text?(value)
        value.instance_of?(String) && value.valid_encoding? && [Encoding::UTF_8,Encoding::US_ASCII].include?(value.encoding)
      end
      def record(value, fields, path)
        fail_at(path) unless value.instance_of?(Hash)
        errors=[]
        unknown = value.keys - fields.keys
        unknown.each { |name| errors << Fault.new('E_INPUT_CONTRACT',ProjectCore.pointer(path,name)) }
        missing = fields.keys - value.keys
        missing.each { |name| errors << Fault.new('E_INPUT_CONTRACT',ProjectCore.pointer(path,name)) }
        validated = {}
        fields.keys.sort.each do |name|
          next unless value.key?(name)
          begin
            validated[name] = check(value[name],fields[name],ProjectCore.pointer(path,name))
          rescue Fault => e
            raise if e.code=='E_RESOURCE_LIMIT'
            errors << e
          end
        end
        raise errors.min_by(&:json_pointer) unless errors.empty?
        fields.keys.each_with_object({}) { |name,h| h[name] = validated[name] }
      end
      def check(value, rule, path)
        @budget.tick(path)
        if rule.instance_of?(Array)
          kind, arg, cap = rule
          if kind == :enum
            fail_at(path) unless arg.include?(value)
            return value
          elsif kind == :array
            fail_at(path) unless value.instance_of?(Array)
            @budget.cap(value.size,cap,path) if cap
            result=Array.new(value.size)
            (0...value.size).sort_by { |i| i.to_s }.each { |i| result[i]=check(value[i],arg,ProjectCore.pointer(path,i)) }
            return result
          end
        end
        case rule
        when :uuid
          fail_at(path) unless text?(value) && value.ascii_only? && UUID.match?(value)
          value
        when :revision, :version, :page
          minimum = rule == :revision ? 0 : 1
          fail_at(path) unless value.instance_of?(Integer) && value >= minimum && value <= SAFE_INTEGER
          value
        when :text
          fail_at(path) unless text?(value)
          value
        when :label
          check(value,:text,path)
          @budget.cap(value.length,:label_chars,path)
          value
        when :boolean
          fail_at(path) unless value == true || value == false
          value
        when :quantity
          Quantities.validate(value,path,@budget)
        when :default
          value.nil? ? nil : check(value,:quantity,path)
        when :parameter_values
          fail_at(path) unless value.instance_of?(Hash)
          @budget.cap(value.size,:parameters,path)
          value.keys.sort.each_with_object({}) do |name,h|
            fail_at(ProjectCore.pointer(path,name)) unless /\A[A-Za-z_][A-Za-z0-9_]*\z/.match?(name)
            h[name] = check(value[name],:quantity,ProjectCore.pointer(path,name))
          end
        when :definition
          record(value,{'id'=>:uuid,'version'=>:version,'label'=>:label,'parameters'=>[:array,:parameter,:parameters],
            'root_zone_id'=>:uuid,'zones'=>[:array,:zone,:zones],'source_refs'=>[:array,:source]},path)
        when :parameter
          record(value,{'name'=>:text,'expected_type'=>:text,'default_value'=>:default,'required'=>:boolean},path)
        when :article
          result = record(value,{'id'=>:uuid,'definition_ref'=>:definition_ref,'parameter_values'=>:parameter_values,'origin'=>[:array,:quantity]},path)
          fail_at(ProjectCore.pointer(path,'origin')) unless result['origin'].size == 3 && result['origin'].all? { |v| v['type'] == 'Length' }
          result
        when :definition_ref
          record(value,{'id'=>:uuid,'version'=>:version},path)
        when :zone
          record(value,{'id'=>:uuid,'orientation'=>[:enum,%w[plan front left_side]],'layout'=>:layout,
            'children'=>[:array,:child],'source_refs'=>[:array,:source]},path)
        when :layout
          fail_at(path) unless value.instance_of?(Hash)
          fields = case value['kind']
          when 'leaf' then {'kind'=>[:enum,['leaf']]}
          when 'partition' then {'kind'=>[:enum,['partition']],'axis'=>[:enum,%w[u v w]],'expression'=>:division_expression,'slots'=>[:array,:slot,:zones]}
          when 'independent_layers' then {'kind'=>[:enum,['independent_layers']],'placements'=>[:array,:placement,:zones]}
          else fail_at(ProjectCore.pointer(path,'kind'))
          end
          record(value,fields,path)
        when :division_expression
          record(value,{'grammar_version'=>[:enum,['jp-division-v1']],'source'=>:expression_source},path)
        when :expression
          record(value,{'grammar_version'=>[:enum,['jp-core-v1']],'source'=>:expression_source,'expected_type'=>[:enum,['Length']]},path)
        when :expression_source
          check(value,:text,path)
          fail_at(path,'E_RESOURCE_LIMIT') if value.length > Parametric::DEFAULT_LIMITS[:source_chars]
          value
        when :child
          record(value,{'zone_id'=>:uuid,'slot_id'=>:uuid},path)
        when :slot
          record(value,{'id'=>:uuid,'role'=>[:enum,%w[zone reservation clearance]]},path)
        when :placement
          record(value,{'id'=>:uuid,'bounds'=>:bounds},path)
        when :bounds
          result = record(value,{'u'=>[:array,:expression],'v'=>[:array,:expression],'w'=>[:array,:expression]},path)
          %w[u v w].each { |axis| fail_at(ProjectCore.pointer(path,axis)) unless result[axis].size == 2 }
          result
        when :source
          fail_at(path) unless value.instance_of?(Hash)
          fields = {'requirement_id'=>:text,'classification'=>[:enum,%w[VERIFIED INFERRED PROPOSED UNKNOWN]],
            'pdf'=>:nullable_text,'page'=>:nullable_page,'conflict_id'=>:nullable_text}
          result = record(value,fields,path)
          if result['classification'] == 'VERIFIED'
            fail_at(ProjectCore.pointer(path,'pdf')) if result['pdf'].nil? || result['pdf'].empty?
            fail_at(ProjectCore.pointer(path,'page')) if result['page'].nil?
          end
          fail_at(path) unless result['pdf'].nil? == result['page'].nil?
          result
        when :nullable_text then value.nil? ? nil : check(value,:text,path)
        when :nullable_page then value.nil? ? nil : check(value,:page,path)
        else fail_at(path)
        end
      end
      def deep_freeze(value)
        stack = [value]
        until stack.empty?
          item = stack.pop
          @budget.tick
          if item.instance_of?(Hash)
            item.each { |key,child| stack << key << child }
          elsif item.instance_of?(Array)
            item.each { |child| stack << child }
          end
          item.freeze
        end
        value
      end
    end
  end
end
