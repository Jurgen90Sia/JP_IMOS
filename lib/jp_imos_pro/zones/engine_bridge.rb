# frozen_string_literal: true
module JPImosPro
  module Zones
    module EngineBridge
      module_function
      def engine_dto(value,budget)
        budget.tick
        value.each_with_object({}) do |(key,child),h|
          h[key.to_sym]=child.instance_of?(Hash) ? engine_dto(child,budget) : child
        end
      end
      def string_dto(value)
        value.each_with_object({}) { |(k,v),h| h[k.to_s]=v.instance_of?(Hash) ? string_dto(v) : v }
      end
      def rational(value)
        Rational(value['numeric']['numerator'],value['numeric']['denominator'])
      end
      def length(value)
        r=value.to_r
        {'type'=>'Length','unit'=>'mm','numeric'=>{'numerator'=>r.numerator.to_s,'denominator'=>r.denominator.to_s,'exact'=>true}}
      end
      def unwrap(result,pointer,occurrence_ref)
        unless result[:ok]
          d=result[:diagnostics].first
          raise ProjectCore::Fault.new(d[:code],pointer,occurrence_ref,d[:details],d)
        end
        result[:value]
      end
      def expression(spec:,symbols:,pointer:,occurrence_ref:,policy:,budget:)
        result=Parametric::Internal.expression(source:spec['source'],symbols:symbols,numeric_policy:policy,shared_counter:budget.counter)
        value=unwrap(result,pointer,occurrence_ref)
        raise ProjectCore::Fault.new('E_UNIT_MISMATCH',pointer,occurrence_ref) unless value[:type]=='Length'
        raise ProjectCore::Fault.new('E_INEXACT_DIVISION_INPUT',pointer,occurrence_ref) unless value[:numeric][:exact]
        string_dto(value)
      end
      def division(spec:,length:,symbols:,pointer:,occurrence_ref:,policy:,budget:)
        reference={length:engine_dto(self.length(length),budget),origin:engine_dto(self.length(0),budget),direction:1}
        result=Parametric::Internal.division(source:spec['source'],reference:reference,symbols:symbols,context:'positive_intervals',numeric_policy:policy,shared_counter:budget.counter)
        unwrap(result,pointer,occurrence_ref)
      end
    end
  end
end
