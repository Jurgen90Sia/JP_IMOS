# frozen_string_literal: true
module JPImosPro
  module Parametric
    class DivisionParser < Parser
      def parse
        terms = []
        loop do
          count = 1
          repeated = false
          if @tokens[@index + 1] && @tokens[@index + 1][0] == '{'
            repeated = true
            token = take
            syntax('E_UNSUPPORTED_GRAMMAR') unless /\A[1-9][0-9]*\z/.match?(token[0])
            count = token[0].to_i
            raise Fault.new('E_RESOURCE_LIMIT') if count > @budget.limit(:expanded_segments)
            take
            tree = sum(0)
            syntax('E_UNSUPPORTED_GRAMMAR') unless peek == '}'
            take
          else
            tree = sum(0)
          end
          quantum = nil
          if peek == '['
            syntax('E_UNSUPPORTED_GRAMMAR') if repeated
            take
            quantum = unary(0)
            syntax('E_UNSUPPORTED_GRAMMAR') unless quantum[0] == :unit && quantum[1][1][0] == :literal
            expect(']')
          end
          syntax('E_UNSUPPORTED_GRAMMAR') if ['{', '[', '}'].include?(peek)
          terms << {tree: tree, count: count, quantum: quantum}
          raise Fault.new('E_RESOURCE_LIMIT') if terms.sum { |term| term[:count] } > @budget.limit(:expanded_segments)
          break unless peek == ':'
          take
        end
        syntax unless peek.nil?
        terms
      end
    end

    class Gap
      attr_reader :weight, :fixed, :exact
      def initialize(weight, fixed, exact)
        @weight, @fixed, @exact = weight, fixed, exact
      end
      def kind
        'Affine'
      end
    end

    class GapEvaluator < Evaluator
      def type(tree, depth = 0)
        if tree[0] == :symbol
          word = tree[1][0]
          fault('E_UNSUPPORTED_GRAMMAR', tree) unless word.start_with?('$') || %w[X Y pi].include?(word)
        end
        if tree[0] == :call
          types = tree[1][1].map { |child| type(child, depth + 1) }
          fault('E_NONLINEAR_DIVISION', tree) if types.include?('Affine')
        end
        super
      end
      def binary_type(op, x, y, tree)
        if %w[+ -].include?(op) && %w[Scalar Length Affine].include?(x) && %w[Scalar Length Affine].include?(y)
          return x if x == y && x != 'Affine'
          return 'Affine'
        end
        if x == 'Affine' || y == 'Affine'
          return 'Affine' if op == '*' && (x == 'Scalar' || y == 'Scalar')
          return 'Affine' if op == '/' && y == 'Scalar'
          fault('E_NONLINEAR_DIVISION', tree)
        end
        fault('E_UNSUPPORTED_LEGACY_UNIT', tree) if op == '/' && x == 'Scalar' && y == 'Length'
        super
      end
      def lift(v)
        return v if v.is_a?(Gap)
        v.kind == 'Scalar' ? Gap.new(v.n, Rational(0), v.exact) : Gap.new(Rational(0), v.n, v.exact)
      end
      def value(tree)
        if tree[0] == :unary
          v = value(tree[1][1])
          if v.is_a?(Gap)
            sign = tree[1][0] == '-' ? -1 : 1
            return Gap.new(@budget.number(sign * v.weight), @budget.number(sign * v.fixed), v.exact)
          end
        end
        super
      end
      def operate(op, a, b, tree)
        kind = binary_type(op, a.kind, b.kind, tree)
        return super unless kind == 'Affine'
        exact = a.exact && b.exact
        case op
        when '+', '-'
          x, y = lift(a), lift(b)
          sign = op == '+' ? 1 : -1
          Gap.new(@budget.number(x.weight + sign*y.weight), @budget.number(x.fixed + sign*y.fixed), exact)
        when '*'
          gap, scalar = a.kind == 'Scalar' ? [lift(b), a.n] : [lift(a), b.n]
          Gap.new(@budget.number(gap.weight*scalar), @budget.number(gap.fixed*scalar), exact)
        when '/'
          fault('E_DIV_ZERO', tree) if b.n.zero?
          gap = lift(a)
          Gap.new(@budget.number(gap.weight/b.n), @budget.number(gap.fixed/b.n), exact)
        end
      end
    end

    module_function
    def parse_division(source:, grammar_version:, limits: {})
      guard(grammar_version, nil, limits) do |budget|
        raise Fault.new('E_UNSUPPORTED_GRAMMAR') unless grammar_version == DIVISION
        terms = DivisionParser.new(source, budget).parse
        freeze_tree({grammar_version: DIVISION, source: source.dup, tree: terms})
      end
    end

    def allocate_division(ast:, reference:, symbols:, context:, numeric_policy:, limits: {})
      guard(DIVISION, numeric_policy, limits) do |budget|
        require_policy(numeric_policy)
        division_value(ast:ast,reference:reference,symbols:symbols,context:context,budget:budget)
      end
    end

    def division_value(ast:,reference:,symbols:,context:,budget:)
        unless exact_keys?(ast, [:grammar_version,:source,:tree]) && ast[:grammar_version] == DIVISION
          raise Fault.new('E_INPUT_CONTRACT', nil, 'ast')
        end
        terms = DivisionParser.new(ast[:source], budget).parse
        raise Fault.new('E_INPUT_CONTRACT', nil, 'ast.tree') unless terms == ast[:tree]
        terms = terms.flat_map do |term|
          budget.tick(term[:count])
          Array.new(term[:count]) { {tree: term[:tree], count: 1, quantum: term[:quantum]} }
        end
        unless exact_keys?(reference, [:direction,:length,:origin]) && [1,-1].include?(reference[:direction]) && reference[:direction].is_a?(Integer)
          raise Fault.new('E_INPUT_CONTRACT', nil, 'reference')
        end
        unless %w[positive_intervals reference_points].include?(context)
          raise Fault.new('E_INPUT_CONTRACT', nil, 'context')
        end
        length = Value.deserialize(reference[:length], budget, 'reference.length')
        origin = Value.deserialize(reference[:origin], budget, 'reference.origin')
        raise Fault.new('E_INPUT_CONTRACT', nil, 'reference') unless length.kind == 'Length' && origin.kind == 'Length'
        raise Fault.new('E_INEXACT_DIVISION_INPUT') unless length.exact && origin.exact
        raise Fault.new('E_REFERENCE_SPAN') unless length.n > 0
        raise Fault.new('E_INPUT_CONTRACT', nil, 'symbols') unless symbols.is_a?(Hash)
        # Y is the one caller-supplied reserved reference dimension.
        env = bindings(symbols.reject { |name,_| name == 'Y' }, budget)
        if symbols.key?('Y')
          env['Y'] = Value.deserialize(symbols['Y'], budget, 'symbols.Y')
          raise Fault.new('E_INPUT_CONTRACT', nil, 'symbols.Y') unless env['Y'].kind == 'Length'
        end
        env['X'] = length
        evaluator = GapEvaluator.new(env, budget)
        dependencies = []
        gaps = terms.map do |term|
          term[:resolved_type] = evaluator.type(term[:tree])
          dependencies |= references(term[:tree], budget)
          value = evaluator.value(term[:tree])
          raise Fault.new('E_UNIT_MISMATCH', term[:tree][2]) if value.kind == 'Boolean'
          gap = evaluator.lift(value)
          raise Fault.new('E_INEXACT_DIVISION_INPUT', term[:tree][2]) unless gap.exact
          raise Fault.new('E_NEGATIVE_WEIGHT', term[:tree][2]) if gap.weight < 0
          gap
        end
        quantized = terms.each_index.select { |i| terms[i][:quantum] }
        quantum = nil
        unless quantized.empty?
          raise Fault.new('E_UNSUPPORTED_GRAMMAR') unless quantized.size == 1
          qi = quantized.first
          unless gaps[qi].weight == 1 && gaps[qi].fixed.zero? && gaps.each_with_index.all? { |gap,i| i == qi || (gap.weight.zero? && terms[i][:resolved_type] == 'Length') }
            raise Fault.new('E_UNSUPPORTED_GRAMMAR')
          end
          evaluator.type(terms[qi][:quantum])
          quantum = evaluator.value(terms[qi][:quantum])
          raise Fault.new('E_INEXACT_DIVISION_INPUT') unless quantum.exact
          raise Fault.new('E_UNSUPPORTED_GRAMMAR') unless quantum.kind == 'Length' && quantum.n > 0
        end
        w, f = Rational(0), Rational(0)
        gaps.each do |gap|
          w = budget.number(w + gap.weight)
          f = budget.number(f + gap.fixed)
        end
        ratio = nil
        if w.zero?
          raise Fault.new('E_SPAN_MISMATCH') unless f == length.n
        else
          ratio = budget.number(budget.number(length.n - f) / w)
          raise Fault.new('E_SPAN_MISMATCH') if ratio < 0
        end
        position = Rational(0)
        boundaries = [{id: 'b0', position: Value.new('Length', position).serialize}]
        expanded = gaps.each_with_index.map do |gap, i|
          budget.tick
          solved = budget.number(budget.number(gap.weight * (ratio || 0)) + gap.fixed)
          terminal = i.zero? || i == gaps.size - 1
          allowed_marker = gap.weight.zero?
          unless solved > 0 || (context == 'reference_points' && terminal && allowed_marker)
            raise Fault.new('E_DEGENERATE_INTERVAL', terms[i][:tree][2], nil, [], {term_index: i})
          end
          position = budget.number(position + solved)
          boundaries << {id: "b#{i+1}", position: Value.new('Length', position).serialize}
          term_result = {id: "t#{i}", weight: Value.new('Scalar',gap.weight).serialize,
            fixed: Value.new('Length',gap.fixed).serialize, length: Value.new('Length',solved).serialize}
          if quantum && quantized.first == i
            count = budget.number(solved / quantum.n)
            raise Fault.new('E_QUANTIZATION_INFEASIBLE') unless count > 0 && count.denominator == 1
            term_result[:quantum_count] = count.numerator
            term_result[:quantum] = quantum.serialize
          end
          term_result
        end
        raise Fault.new('E_SPAN_MISMATCH') unless position == length.n
        mapped = boundaries.map do |boundary|
          data = boundary[:position][:numeric]
          p = Rational(data[:numerator],data[:denominator])
          {id: boundary[:id], position: Value.new('Length',budget.number(origin.n + reference[:direction]*p)).serialize}
        end
        {grammar_version: DIVISION, context: context,
          reference: {length: length.serialize, origin: origin.serialize, direction: reference[:direction]},
          expanded_terms: expanded, local_boundaries: boundaries, mapped_boundaries: mapped,
          internal_points: boundaries[1...-1], ratio_or_null: ratio && Value.new('Length',ratio).serialize,
          dependencies: dependencies.sort, exact: true}
    end
  end
end
