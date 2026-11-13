# frozen_string_literal: true
module JPImosPro
  module Parametric
    # Trusted domain adapter. No shared object is sourced from public AST,
    # symbols or numeric-policy data; no thread-local/global request state.
    module Internal
      module_function
      def expression(source:,symbols:,numeric_policy:,shared_counter:)
        budget=Budget.new({},shared_counter:shared_counter)
        Parametric.guard(CORE,numeric_policy,{},budget) do |b|
          Parametric.require_policy(numeric_policy)
          tree=Parser.new(source,b).parse
          evaluator=Evaluator.new(Parametric.bindings(symbols,b),b)
          evaluator.type(tree)
          evaluator.value(tree).serialize
        end
      end
      def division(source:,reference:,symbols:,context:,numeric_policy:,shared_counter:)
        budget=Budget.new({},shared_counter:shared_counter)
        Parametric.guard(DIVISION,numeric_policy,{},budget) do |b|
          Parametric.require_policy(numeric_policy)
          tree=DivisionParser.new(source,b).parse
          ast={grammar_version:DIVISION,source:source,tree:tree}
          Parametric.division_value(ast:ast,reference:reference,symbols:symbols,context:context,budget:b)
        end
      end
    end
  end
end
