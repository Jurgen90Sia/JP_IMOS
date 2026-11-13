# frozen_string_literal: true
module JPImosPro
  module Parametric
    class Fault < StandardError
      attr_reader :code, :span, :path, :ids, :details
      def initialize(code, span = nil, path = nil, ids = [], details = {})
        @code, @span, @path, @ids, @details = code, span, path, ids, details
        super(code)
      end
    end

    class Budget
      def initialize(limits)
        raise Fault.new('E_INPUT_CONTRACT', nil, 'limits') unless limits.is_a?(Hash)
        @limits = DEFAULT_LIMITS.merge(limits)
        limits.each do |key, value|
          unless DEFAULT_LIMITS.key?(key) && value.is_a?(Integer) && value > 0 && value <= DEFAULT_LIMITS[key]
            raise Fault.new('E_INPUT_CONTRACT', nil, "limits.#{key}")
          end
        end
        @steps = 0
      end
      def limit(key)
        @limits.fetch(key)
      end
      def tick(count = 1)
        @steps += count
        raise Fault.new('E_RESOURCE_LIMIT') if @steps > limit(:steps)
      end
      def number(r)
        raise Fault.new('E_RESOURCE_LIMIT') if r.numerator.bit_length > limit(:numeric_bits) || r.denominator.bit_length > limit(:numeric_bits)
        r
      end
    end

    class Value
      attr_reader :kind, :n, :exact
      def initialize(kind, n, exact = true)
        @kind, @n, @exact = kind, n, exact
        freeze
      end
      def serialize
        return {type: 'Boolean', value: @n} if @kind == 'Boolean'
        h = {type: @kind, numeric: {numerator: @n.numerator.to_s,
          denominator: @n.denominator.to_s, exact: @exact}}
        h[:unit] = 'mm' if @kind == 'Length'
        h
      end
      def self.deserialize(h, budget, path)
        fail_input = proc { raise Fault.new('E_INPUT_CONTRACT', nil, path) }
        fail_input.call unless h.is_a?(Hash)
        if h[:type] == 'Boolean'
          fail_input.call unless h.keys.sort == [:type, :value] && [true, false].include?(h[:value])
          return new('Boolean', h[:value])
        end
        kind = h[:type]
        keys = kind == 'Length' ? [:numeric, :type, :unit] : [:numeric, :type]
        fail_input.call unless %w[Scalar Length].include?(kind) && h.keys.sort == keys && (kind != 'Length' || h[:unit] == 'mm')
        data = h[:numeric]
        fail_input.call unless data.is_a?(Hash) && data.keys.sort == [:denominator, :exact, :numerator]
        a, b = data[:numerator], data[:denominator]
        fail_input.call unless a.is_a?(String) && b.is_a?(String) && a.length <= 1235 && b.length <= 1235 && /\A-?(0|[1-9][0-9]*)\z/.match?(a) && /\A[1-9][0-9]*\z/.match?(b) && [true, false].include?(data[:exact])
        r = budget.number(Rational(a.to_i, b.to_i))
        fail_input.call unless r.numerator.to_s == a && r.denominator.to_s == b
        new(kind, r, data[:exact])
      end
    end

    class Parser
      attr_reader :tokens
      def initialize(source, budget)
        raise Fault.new('E_INPUT_CONTRACT', nil, 'source') unless source.is_a?(String) && source.valid_encoding?
        @source, @budget, @index, @nodes = source, budget, 0, 0
        raise Fault.new('E_RESOURCE_LIMIT') if source.length > budget.limit(:source_chars)
        @tokens = []
        i = 0
        while i < source.length
          budget.tick
          tail = source[i..-1]
          if (m = /\A[ \t\r\n]+/.match(tail))
            i += m[0].length
            next
          end
          m = /\A(?:[0-9]+(?:\.[0-9]+)?|\$?[A-Za-z_][A-Za-z0-9_]*|<=|>=|==|!=|[+\-*\/%()<>,:{}\[\]])/.match(tail)
          unless m
            code = %w[^ #].include?(source[i]) ? 'E_UNSUPPORTED_GRAMMAR' : 'E_FORBIDDEN_TOKEN'
            raise Fault.new(code, {start: i, end: i + 1})
          end
          word = m[0]
          raise Fault.new('E_UNSUPPORTED_GRAMMAR', {start: i, end: i + 2}) if tail.start_with?('**')
          if /\A[0-9]/.match?(word)
            raise Fault.new('E_SYNTAX', {start: i, end: i + word.length + 1}) if /\A[0-9]+(?:\.[0-9]+)?[eE][+-]?[0-9]/.match?(tail)
            raise Fault.new('E_RESOURCE_LIMIT') if word.delete('.').length > budget.limit(:literal_digits)
          end
          @tokens << [word, i, i + word.length]
          raise Fault.new('E_RESOURCE_LIMIT') if @tokens.size > budget.limit(:tokens)
          i += word.length
        end
        @tokens << [nil, source.length, source.length]
      end
      def peek
        @tokens[@index][0]
      end
      def take
        t = @tokens[@index]
        @index += 1
        t
      end
      def expect(word)
        syntax unless peek == word
        take
      end
      def syntax(code = 'E_SYNTAX')
        t = @tokens[@index] || @tokens.last
        raise Fault.new(code, {start: t[1], end: t[2]})
      end
      def node(kind, args, start, finish)
        @budget.tick
        @nodes += 1
        raise Fault.new('E_RESOURCE_LIMIT') if @nodes > @budget.limit(:ast_nodes)
        [kind, args, {start: start, end: finish}]
      end
      def parse
        result = expression(0)
        syntax unless peek.nil?
        result
      end
      def expression(depth)
        left = sum(depth)
        if %w[< > <= >= == !=].include?(peek)
          op = take[0]
          right = sum(depth)
          left = node(:binary, [op, left, right], left[2][:start], right[2][:end])
        end
        left
      end
      def sum(depth)
        left = product(depth)
        while %w[+ -].include?(peek)
          op = take[0]
          right = product(depth)
          left = node(:binary, [op, left, right], left[2][:start], right[2][:end])
        end
        left
      end
      def product(depth)
        left = unary(depth)
        while %w[* / %].include?(peek)
          op = take[0]
          right = unary(depth)
          left = node(:binary, [op, left, right], left[2][:start], right[2][:end])
        end
        left
      end
      def unary(depth)
        raise Fault.new('E_RESOURCE_LIMIT') if depth > @budget.limit(:depth)
        if %w[+ -].include?(peek)
          t = take
          child = unary(depth + 1)
          return node(:unary, [t[0], child], t[1], child[2][:end])
        end
        t = take
        word = t[0]
        syntax if word.nil?
        suffix = false
        if /\A[0-9]/.match?(word)
          r = @budget.number(Rational(word))
          result = node(:literal, [r.numerator.to_s, r.denominator.to_s], t[1], t[2])
          suffix = true
        elsif word == '('
          result = expression(depth + 1)
          ending = expect(')')
          result = node(:group, [result], t[1], ending[2])
          suffix = true
        elsif %w[true false].include?(word)
          result = node(:boolean, [word == 'true'], t[1], t[2])
        elsif /\A\$?[A-Za-z_][A-Za-z0-9_]*\z/.match?(word)
          if peek == '(' && !word.start_with?('$')
            take
            args = []
            unless peek == ')'
              loop do
                args << expression(depth + 1)
                raise Fault.new('E_RESOURCE_LIMIT') if args.size > @budget.limit(:function_args)
                break unless peek == ','
                take
              end
            end
            ending = expect(')')
            result = node(:call, [word, args], t[1], ending[2])
          else
            result = node(:symbol, [word], t[1], t[2])
          end
        else
          raise Fault.new('E_SYNTAX', {start: t[1], end: t[2]})
        end
        if suffix && peek && /\A[A-Za-z_]/.match?(peek)
          unit = take
          raise Fault.new('E_UNKNOWN_UNIT', {start: unit[1], end: unit[2]}) unless %w[mm cm m].include?(unit[0])
          result = node(:unit, [unit[0], result], t[1], unit[2])
        end
        result
      end
    end

    class Evaluator
      def initialize(env, budget)
        @env, @budget = env, budget
      end
      def fault(code, tree, ids = [])
        raise Fault.new(code, tree[2], nil, ids)
      end
      def type(tree, depth = 0)
        @budget.tick
        fault('E_RESOURCE_LIMIT', tree) if depth > @budget.limit(:depth)
        kind, args = tree
        case kind
        when :literal then 'Scalar'
        when :boolean then 'Boolean'
        when :symbol
          name = args[0].sub(/\A\$/, '')
          return 'Scalar' if name == 'pi'
          fault('E_UNKNOWN_SYMBOL', tree, [name]) unless @env.key?(name)
          @env[name].kind
        when :group then type(args[0], depth + 1)
        when :unit
          fault('E_UNIT_MISMATCH', tree) unless type(args[1], depth + 1) == 'Scalar'
          'Length'
        when :unary
          t = type(args[1], depth + 1)
          fault('E_UNIT_MISMATCH', tree) if t == 'Boolean'
          t
        when :binary
          op, a, b = args
          x, y = type(a, depth + 1), type(b, depth + 1)
          binary_type(op, x, y, tree)
        else
          fault('E_UNKNOWN_FUNCTION', tree)
        end
      end
      def binary_type(op, x, y, tree)
        if %w[< > <= >= == !=].include?(op)
          fault('E_UNIT_MISMATCH', tree) unless x == y && (x != 'Boolean' || %w[== !=].include?(op))
          return 'Boolean'
        end
        fault('E_UNIT_MISMATCH', tree) if x == 'Boolean' || y == 'Boolean'
        case op
        when '+', '-'
          fault('E_UNIT_MISMATCH', tree) unless x == y
          x
        when '*'
          fault('E_UNIT_MISMATCH', tree) unless x == 'Scalar' || y == 'Scalar'
          x == 'Length' || y == 'Length' ? 'Length' : 'Scalar'
        when '/'
          fault('E_UNIT_MISMATCH', tree) if x == 'Scalar' && y == 'Length'
          x == y ? 'Scalar' : 'Length'
        when '%'
          fault('E_UNIT_MISMATCH', tree) unless x == 'Scalar' && y == 'Scalar'
          'Scalar'
        end
      end
      def value(tree)
        @budget.tick
        kind, args = tree
        case kind
        when :literal then Value.new('Scalar', @budget.number(Rational(args[0], args[1])))
        when :boolean then Value.new('Boolean', args[0])
        when :symbol
          name = args[0].sub(/\A\$/, '')
          name == 'pi' ? Value.new('Scalar', Rational(3141592653589793, 10**15), false) : @env.fetch(name)
        when :group then value(args[0])
        when :unit
          v = value(args[1])
          Value.new('Length', @budget.number(v.n * {'mm'=>1, 'cm'=>10, 'm'=>1000}.fetch(args[0])), v.exact)
        when :unary
          v = value(args[1])
          Value.new(v.kind, @budget.number(args[0] == '-' ? -v.n : v.n), v.exact)
        when :binary
          op, a, b = args
          operate(op, value(a), value(b), tree)
        end
      end
      def operate(op, a, b, tree)
        kind = binary_type(op, a.kind, b.kind, tree)
        if kind == 'Boolean'
          n = case op
          when '<' then a.n < b.n
          when '>' then a.n > b.n
          when '<=' then a.n <= b.n
          when '>=' then a.n >= b.n
          when '==' then a.n == b.n
          when '!=' then a.n != b.n
          end
          return Value.new(kind, n)
        end
        n = case op
        when '+' then a.n + b.n
        when '-' then a.n - b.n
        when '*' then a.n * b.n
        when '/'
          fault('E_DIV_ZERO', tree) if b.n.zero?
          a.n / b.n
        when '%'
          fault('E_DOMAIN', tree) unless a.n.denominator == 1 && b.n.denominator == 1 && a.n >= 0 && b.n > 0
          a.n % b.n
        end
        Value.new(kind, @budget.number(n), a.exact && b.exact)
      end
    end
  end
end
