require 'minitest/autorun'
require_relative '../lib/jp_imos_pro/parametric'

class EngineTest < Minitest::Test
  P = JPImosPro::Parametric
  POLICY = {policy_id: 'jp-rational-binary64-15-v1', backend_id: "#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"}.freeze
  def quantity(n, kind = 'Scalar', exact = true)
    r = Rational(n)
    h = {type: kind, numeric: {numerator: r.numerator.to_s, denominator: r.denominator.to_s, exact: exact}}
    h[:unit] = 'mm' if kind == 'Length'
    h
  end
  def expression(source, symbols = {})
    parsed = P.parse_expression(source: source, grammar_version: 'jp-core-v1')
    return parsed unless parsed[:ok]
    P.evaluate_expression(ast: parsed[:value], symbols: symbols, numeric_policy: POLICY)
  end
  def number(result)
    assert result[:ok], result[:diagnostics].inspect
    n = result[:value][:numeric]
    Rational(n[:numerator], n[:denominator])
  end
  def error(code, result)
    refute result[:ok]
    assert_equal code, result[:diagnostics].first[:code]
    assert_nil result[:value]
  end
  def test_exact_decimal_and_typed_dimensions
    assert_equal Rational(3, 10), number(expression('0.1+0.2'))
    assert_equal 564, number(expression('W-2*T', {'W'=>quantity(600,'Length'), 'T'=>quantity(18,'Length')}))
    assert_equal 2100, number(expression('2m+10cm'))
    assert_equal 2, number(expression('(8/4)mm'))
  end
  def test_unit_errors_and_unsafe_input
    error('E_UNIT_MISMATCH', expression('1mm+1'))
    error('E_UNIT_MISMATCH', expression('8/4mm'))
    error('E_FORBIDDEN_TOKEN', expression('File.read("x")'))
    error('E_INPUT_CONTRACT', expression('a', {'a'=>1.5}))
    error('E_SYNTAX', expression('1e999'))
    error('E_RESOURCE_LIMIT', expression('1'*4097))
    error('E_RESOURCE_LIMIT', expression('('*33+'1'+')'*33))
  end
end
