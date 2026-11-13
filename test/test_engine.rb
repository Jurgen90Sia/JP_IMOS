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
  def test_functions_are_typed_and_conditional_is_lazy
    assert_in_delta 1, number(expression('sin(pi/2)')).to_f, 1e-12
    refute expression('sin(pi/2)')[:value][:numeric][:exact]
    assert_equal 10, number(expression('if(true,10mm,1mm/0)'))
    assert_equal 7, number(expression('max(abs(-3),min(7,8))'))
    assert_equal 1, number(expression('5%2'))
    error('E_UNIT_MISMATCH', expression('if(true,10mm,1)'))
    error('E_UNKNOWN_SYMBOL', expression('if(true,1,missing)'))
    error('E_FUNCTION_DOMAIN', expression('asin(2)'))
    error('E_FUNCTION_DOMAIN', expression('tan(pi/2)'))
    error('E_UNKNOWN_FUNCTION', expression('atan(1)'))
    error('E_DIV_ZERO', expression('1/0'))
    error('E_DOMAIN', expression('-1%2'))
    error('E_SYNTAX', expression('1<2<3'))
    error('E_UNSUPPORTED_GRAMMAR', expression('2**3'))
  end
  def definitions(defs, inputs = {})
    P.evaluate_definitions(definitions: defs, inputs: inputs, numeric_policy: POLICY)
  end
  def test_definitions_have_atomic_deterministic_dependency_resolution
    defs = {'b'=>{source: 'a*2', expected_type: 'Length'}, 'a'=>{source: 'T+1mm', expected_type: 'Length'}}
    result = definitions(defs, {'T'=>quantity(18,'Length')})
    assert result[:ok], result.inspect
    assert_equal ['a','b'], result[:value][:order]
    assert_equal '38', result[:value][:symbols]['b'][:numeric][:numerator]
    error('E_DEPENDENCY_CYCLE', definitions({'a'=>{source:'b',expected_type:'Scalar'},'b'=>{source:'a',expected_type:'Scalar'}}))
    error('E_DEPENDENCY_CYCLE', definitions({'a'=>{source:'if(true,1,a)',expected_type:'Scalar'}}))
    error('E_UNKNOWN_SYMBOL', definitions({'a'=>{source:'if(true,1,missing)',expected_type:'Scalar'}}))
    error('E_DUPLICATE_SYMBOL', definitions({'a'=>{source:'1',expected_type:'Scalar'}}, {'a'=>quantity(0)}))
    error('E_RESERVED_SYMBOL', expression('pi', {'pi'=>quantity(0)}))
    assert_equal 0, number(expression('$a', {'a'=>quantity(0)}))
    error('E_UNKNOWN_SYMBOL', expression('$a'))
  end
  def division(source, length = 600, context = 'positive_intervals', symbols = {}, origin = 0, direction = 1)
    parsed = P.parse_division(source: source, grammar_version: 'jp-division-v1')
    return parsed unless parsed[:ok]
    P.allocate_division(ast: parsed[:value], reference: {length: quantity(length,'Length'), origin: quantity(origin,'Length'), direction: direction},
      symbols: symbols, context: context, numeric_policy: POLICY)
  end
  def lengths(result)
    assert result[:ok], result[:diagnostics].inspect
    result[:value][:expanded_terms].map { |t| n = t[:length][:numeric]; Rational(n[:numerator],n[:denominator]) }
  end
  def test_manual_division_fixtures_E01_to_E11_and_affine_lifting
    cases = [
      ['1:1',600,'positive_intervals',[300,300]],
      ['0:1:0',600,'reference_points',[0,600,0]],
      ['77mm:1:77mm',600,'reference_points',[77,446,77]],
      ['88mm:1:88mm',600,'reference_points',[88,424,88]],
      ['20mm:64mm:1:1:1:64mm:35mm',1000,'positive_intervals',[20,64,Rational(817,3),Rational(817,3),Rational(817,3),64,35]],
      ['20mm:64mm:1:2:1:64mm:35mm',1000,'positive_intervals',[20,64,Rational(817,4),Rational(817,2),Rational(817,4),64,35]],
      ['-200mm:1:-200mm',1000,'reference_points',[-200,1400,-200]],
      ['1+100mm:1:1+50mm',600,'positive_intervals',[250,150,200]],
      ['1:X-100mm',600,'positive_intervals',[100,500]],
      ['1-100mm:1',600,'positive_intervals',[250,350]],
      ['2*3:1',700,'positive_intervals',[600,100]],
      ['2*(1+100mm):1',800,'positive_intervals',[600,200]]]
    cases.each { |source,l,c,want| assert_equal want, lengths(division(source,l,c)), source }
    assert_equal [590,10], lengths(division('1:2*($a+$b)mm',600,'positive_intervals',{'a'=>quantity(2),'b'=>quantity(3)}))
    result = division('1:1',600,'positive_intervals',{},20,-1)
    assert_equal ['20','-280','-580'], result[:value][:mapped_boundaries].map { |b| b[:position][:numeric][:numerator] }
    assert_equal ['b1','b2'], division('0:1:0',600,'reference_points')[:value][:internal_points].map { |p| p[:id] }
  end
  def test_division_rejects_invalid_geometry_and_nonlinear_formulas
    [['E_SPAN_MISMATCH','77mm:1:77mm',153],['E_DEGENERATE_INTERVAL','77mm:1:77mm',154],
     ['E_DEGENERATE_INTERVAL','0:1:0',600],['E_DEGENERATE_INTERVAL','-200mm:1:-200mm',1000],
     ['E_NEGATIVE_WEIGHT','1:-1',600],['E_SPAN_MISMATCH','100mm:200mm',301],
     ['E_REFERENCE_SPAN','1:1',0],['E_NONLINEAR_DIVISION','(1+10mm)*(1+10mm):1',600],
     ['E_NONLINEAR_DIVISION','abs(1+100mm):1',600],['E_UNSUPPORTED_LEGACY_UNIT','8/4mm:1',600]].each do |code,s,l|
      error(code, division(s,l))
    end
    assert_equal [2,598], lengths(division('(8/4)mm:1'))
    fixed = division('100mm:200mm',300)
    assert_equal [100,200], lengths(fixed)
    assert_nil fixed[:value][:ratio_or_null]
    error('E_INEXACT_DIVISION_INPUT', division('sin(pi/2):1'))
    assert_equal [300,300], lengths(division('1:1',600,'positive_intervals',{'unused'=>quantity(1,'Scalar',false)}))
  end
end
