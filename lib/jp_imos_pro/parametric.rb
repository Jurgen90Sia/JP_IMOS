# frozen_string_literal: true
require_relative 'parametric/core'
require_relative 'parametric/division'

module JPImosPro
  module Parametric
    VERSION = '0.1.0'
    CORE = 'jp-core-v1'
    DIVISION = 'jp-division-v1'
    DEFAULT_LIMITS = {source_chars: 4096, tokens: 1024, ast_nodes: 1024,
      depth: 32, literal_digits: 256, numeric_bits: 4096,
      expanded_segments: 1000, definitions: 1000, steps: 10_000,
      function_args: 16}.freeze
    POLICY = 'jp-rational-binary64-15-v1'
    module_function

    def exact_keys?(value, keys)
      value.is_a?(Hash) && value.size == keys.size && keys.all? { |key| value.key?(key) }
    end

    def ascii_text?(value)
      value.is_a?(String) && value.valid_encoding? && value.encoding.ascii_compatible? && value.ascii_only?
    end

    def guard(grammar, policy = nil, limits = {})
      budget = Budget.new(limits)
      if policy && (!policy.is_a?(Hash) || policy[:policy_id] != POLICY ||
          !policy[:backend_id].is_a?(String) || policy[:backend_id].strip.empty?)
        raise Fault.new('E_INPUT_CONTRACT', nil, 'numeric_policy')
      end
      value = yield budget
      {ok: true, value: value, diagnostics: [], metadata: metadata(grammar, policy)}
    rescue Fault => e
      {ok: false, value: nil, diagnostics: [{code: e.code, severity: 'error',
        grammar_version: grammar, source_span: e.span, input_path: e.path,
        symbol_ids: e.ids, message_key: e.code.downcase, details: e.details}],
        metadata: metadata(grammar, policy)}
    end

    def metadata(grammar, policy)
      {grammar_version: grammar, policy_id: policy.is_a?(Hash) ? policy[:policy_id] : nil,
        backend_id: policy.is_a?(Hash) ? policy[:backend_id] : nil}
    end

    def require_policy(policy)
      unless policy.is_a?(Hash) && policy[:policy_id] == POLICY && policy[:backend_id].is_a?(String) && !policy[:backend_id].strip.empty?
        raise Fault.new('E_INPUT_CONTRACT', nil, 'numeric_policy')
      end
    end

    def parse_expression(source:, grammar_version:, limits: {})
      guard(grammar_version, nil, limits) do |budget|
        raise Fault.new('E_UNSUPPORTED_GRAMMAR') unless grammar_version == CORE
        tree = Parser.new(source, budget).parse
        freeze_tree({grammar_version: CORE, source: source.dup, tree: tree})
      end
    end

    # Reparse untrusted AST envelopes and compare the supplied tree. No caller
    # object or fabricated node is executed, even when an envelope was mutated.
    def validated_tree(ast, grammar, budget)
      unless exact_keys?(ast, [:grammar_version, :source, :tree]) && ast[:grammar_version] == grammar
        raise Fault.new('E_INPUT_CONTRACT', nil, 'ast')
      end
      tree = Parser.new(ast[:source], budget).parse
      raise Fault.new('E_INPUT_CONTRACT', nil, 'ast.tree') unless tree == ast[:tree]
      tree
    end

    def evaluate_expression(ast:, symbols:, numeric_policy:, limits: {})
      dependencies = []
      result = guard(CORE, numeric_policy, limits) do |budget|
        require_policy(numeric_policy)
        tree = validated_tree(ast, CORE, budget)
        env = bindings(symbols, budget)
        evaluator = Evaluator.new(env, budget)
        evaluator.type(tree)
        dependencies = references(tree, budget)
        evaluated = evaluator.value(tree).serialize
        dependencies_used = evaluator.dependencies
        [evaluated, dependencies_used]
      end
      if result[:ok]
        result[:value], result[:dependencies] = result[:value]
        result[:declared_dependencies] = dependencies
      end
      result
    end

    def bindings(symbols, budget)
      raise Fault.new('E_INPUT_CONTRACT', nil, 'symbols') unless symbols.is_a?(Hash)
      raise Fault.new('E_RESOURCE_LIMIT') if symbols.size > budget.limit(:definitions)
      symbols.each_with_object({}) do |(name, value), env|
        validate_name(name, 'symbols')
        env[name] = Value.deserialize(value, budget, "symbols.#{name}")
      end
    end

    def references(tree, budget, found = [])
      budget.tick
      kind, args = tree
      if kind == :symbol
        name = args[0].sub(/\A\$/, '')
        found << name unless name == 'pi'
      elsif kind == :call
        args[1].each { |child| references(child, budget, found) }
      else
        args.each { |child| references(child, budget, found) if child.is_a?(Array) }
      end
      found.uniq.sort
    end

    def evaluate_definitions(definitions:, inputs:, numeric_policy:, limits: {})
      guard(CORE, numeric_policy, limits) do |budget|
        require_policy(numeric_policy)
        env = bindings(inputs, budget)
        raise Fault.new('E_INPUT_CONTRACT', nil, 'definitions') unless definitions.is_a?(Hash)
        raise Fault.new('E_RESOURCE_LIMIT') if definitions.size > budget.limit(:definitions)
        trees, types = {}, {}
        definitions.each do |name, definition|
          budget.tick
          validate_name(name, 'definitions')
          raise Fault.new('E_DUPLICATE_SYMBOL', nil, "definitions.#{name}", [name]) if env.key?(name)
          unless exact_keys?(definition, [:expected_type, :source]) && %w[Scalar Length Boolean].include?(definition[:expected_type])
            raise Fault.new('E_INPUT_CONTRACT', nil, "definitions.#{name}")
          end
          trees[name] = Parser.new(definition[:source], budget).parse
          types[name] = definition[:expected_type]
        end
        graph = trees.each_with_object({}) do |(name, tree), h|
          h[name] = references(tree, budget)
          unknown = h[name].reject { |id| trees.key?(id) || env.key?(id) }
          raise Fault.new('E_UNKNOWN_SYMBOL', tree[2], nil, unknown) unless unknown.empty?
          h[name].select! { |id| trees.key?(id) }
        end
        # Kahn's algorithm avoids recursion on a 1000-definition chain.
        order = []
        counts, reverse = {}, Hash.new { |hash,key| hash[key] = [] }
        graph.each do |name, deps|
          counts[name] = deps.size
          deps.each { |dep| budget.tick; reverse[dep] << name }
        end
        ready = counts.select { |_name,count| count.zero? }.keys.sort
        until ready.empty?
          budget.tick
          name = ready.shift
          order << name
          reverse[name].each do |dependent|
            budget.tick
            counts[dependent] -= 1
            if counts[dependent].zero?
              index = ready.bsearch_index { |id| id >= dependent } || ready.size
              ready.insert(index,dependent)
            end
          end
        end
        if order.size != graph.size
            pending = graph.reject { |name,_| counts[name].zero? }
            start = pending.keys.sort.first
            path, seen, current = [], {}, start
            until seen.key?(current)
              budget.tick
              seen[current] = path.size
              path << current
              current = pending.fetch(current).select { |id| pending.key?(id) }.sort.first
            end
            cycle = path[seen[current]..-1] + [current]
            raise Fault.new('E_DEPENDENCY_CYCLE', nil, nil, cycle, {cycle: cycle})
        end
        order.each do |name|
          evaluator = Evaluator.new(env, budget)
          raise Fault.new('E_UNIT_MISMATCH', trees[name][2], nil, [name]) unless evaluator.type(trees[name]) == types[name]
          env[name] = evaluator.value(trees[name])
        end
        {symbols: env.transform_values(&:serialize), order: order,
          dependencies: graph}
      end
    end

    def validate_name(name, path)
      raise Fault.new('E_INPUT_CONTRACT', nil, path) unless ascii_text?(name) && /\A[A-Za-z_][A-Za-z0-9_]*\z/.match?(name)
      raise Fault.new('E_RESERVED_SYMBOL', nil, path, [name]) if %w[pi true false X Y abs min max if sin cos tan asin acos].include?(name)
    end

    def freeze_tree(value)
      case value
      when Hash then value.each { |k, v| freeze_tree(k); freeze_tree(v) }
      when Array then value.each { |v| freeze_tree(v) }
      end
      value.freeze
    end
  end
end
