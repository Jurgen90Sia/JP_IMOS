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
  def test_repeat_and_exact_grid_do_not_guess_legacy_grammar
    assert_equal [100]*8, lengths(division('8{1}',800))
    result = division('20mm:1[32mm]:228mm:96mm')
    assert_equal [20,256,228,96], lengths(result)
    assert_equal 8, result[:value][:expanded_terms][1][:quantum_count]
    error('E_QUANTIZATION_INFEASIBLE', division('20mm:1[32mm]:228mm:96mm',601))
    error('E_UNSUPPORTED_GRAMMAR', division('n*110mm:1'))
    error('E_UNSUPPORTED_GRAMMAR', division('#descriptor'))
    error('E_UNSUPPORTED_GRAMMAR', division('8{1:1}'))
    error('E_UNSUPPORTED_GRAMMAR', division('8{2{1}}'))
    error('E_RESOURCE_LIMIT', division('1001{1}'))
    error('E_UNSUPPORTED_GRAMMAR', division('1[32mm]:1'))
    error('E_UNSUPPORTED_GRAMMAR', division('2[32mm]:20mm'))
    error('E_UNSUPPORTED_GRAMMAR', division('1[0mm]:20mm'))
    error('E_DEGENERATE_INTERVAL', division('1:0:1',600,'reference_points'))
  end
  def test_malformed_contracts_never_escape_as_native_exceptions
    [nil, 1, {}, {type:'Scalar', numeric:{numerator:'1',denominator:'0',exact:true}},
      {type:'Scalar', numeric:{numerator:'2',denominator:'2',exact:true}},
      {type:'Scalar', numeric:{numerator:'1',denominator:'1',exact:0}},
      {type:'Scalar','numeric'=>{}}, {type:'Boolean',value:1}].each do |bad|
      result = expression('a', {'a'=>bad})
      error('E_INPUT_CONTRACT', result)
      assert_nil result[:diagnostics][0][:source_span]
      refute_nil result[:diagnostics][0][:input_path]
    end
    error('E_INPUT_CONTRACT', P.parse_expression(source: 1,grammar_version:'jp-core-v1'))
    error('E_INPUT_CONTRACT', P.parse_expression(source:'1',grammar_version:'jp-core-v1',limits:{'depth'=>2}))
    error('E_INPUT_CONTRACT', P.evaluate_expression(ast:{grammar_version:'jp-core-v1','tree'=>[]},symbols:{},numeric_policy:POLICY))
    error('E_INPUT_CONTRACT', expression('1',{'a'=>quantity(1).merge('other'=>0)}))
    parsed = P.parse_expression(source:'1',grammar_version:'jp-core-v1')[:value]
    assert parsed.frozen?
    assert parsed[:tree].frozen?
    forged = parsed.merge(tree: [:literal,['999','1'],{start:0,end:1}])
    error('E_INPUT_CONTRACT', P.evaluate_expression(ast:forged,symbols:{},numeric_policy:POLICY))
  end
  def test_each_resource_limit_can_be_tightened_but_not_enlarged
    [['1+2',{tokens:2}],['1+2',{ast_nodes:2}],['123',{literal_digits:2}],
     ['1+2',{steps:2}],['((1))',{depth:1}]].each do |source,limits|
      error('E_RESOURCE_LIMIT',P.parse_expression(source:source,grammar_version:'jp-core-v1',limits:limits))
    end
    error('E_INPUT_CONTRACT', P.parse_expression(source:'1',grammar_version:'jp-core-v1',limits:{depth:33}))
    error('E_RESOURCE_LIMIT',P.parse_expression(source:'1'*257,grammar_version:'jp-core-v1'))
    result = P.parse_expression(source:'255*255',grammar_version:'jp-core-v1')
    error('E_RESOURCE_LIMIT',P.evaluate_expression(ast:result[:value],symbols:{},numeric_policy:POLICY,limits:{numeric_bits:8}))
    error('E_RESOURCE_LIMIT',P.parse_division(source:'1:1:1',grammar_version:'jp-division-v1',limits:{expanded_segments:2}))
    error('E_RESOURCE_LIMIT',P.evaluate_definitions(definitions:{'a'=>{source:'1',expected_type:'Scalar'},'b'=>{source:'2',expected_type:'Scalar'}},inputs:{},numeric_policy:POLICY,limits:{definitions:1}))
  end
  def test_remaining_negative_and_boundary_contracts
    %w[NaN Infinity].each { |s| error('E_SYNTAX', expression(s)) }
    ['`whoami`','Kernel.system(1)','1;2','a=1',"'x'"].each do |s|
      result = expression(s)
      refute result[:ok]
      assert_includes ['E_FORBIDDEN_TOKEN','E_SYNTAX'],result[:diagnostics][0][:code]
    end
    error('E_UNIT_MISMATCH',expression('(1mm)cm'))
    error('E_UNKNOWN_UNIT',expression('1inch'))
    error('E_DOMAIN',expression('1%0'))
    error('E_FUNCTION_DOMAIN',expression('sin(1000001)'))
    error('E_INEXACT_DIVISION_INPUT',division('$a:1',600,'positive_intervals',{'a'=>quantity(1,'Scalar',false)}))
    assert_equal [192,408],lengths(division('$n*96mm:1',600,'positive_intervals',{'n'=>quantity(2)}))
    assert_equal [300,300],lengths(division('1:Y',600,'positive_intervals',{'Y'=>quantity(300,'Length')}))
    error('E_UNKNOWN_SYMBOL',division('1:Y'))
    result = expression('if(true,a,b)',{'a'=>quantity(1),'b'=>quantity(2)})
    assert_equal ['a'],result[:dependencies]
    assert_equal ['a','b'],result[:declared_dependencies]
    parsed = P.parse_division(source:'1:1',grammar_version:'jp-division-v1')[:value]
    [[:length,quantity(600,'Length',false)],[:origin,quantity(0,'Length',false)]].each do |key,bad|
      ref = {length:quantity(600,'Length'),origin:quantity(0,'Length'),direction:1}.merge(key=>bad)
      error('E_INEXACT_DIVISION_INPUT',P.allocate_division(ast:parsed,reference:ref,symbols:{},context:'positive_intervals',numeric_policy:POLICY))
    end
  end
  def test_review_regressions_encoding_policy_and_reserved_functions
    error('E_INPUT_CONTRACT',P.parse_expression(source:'1'.encode('UTF-16LE'),grammar_version:'jp-core-v1'))
    ast = P.parse_expression(source:'1',grammar_version:'jp-core-v1')[:value]
    [nil,false,{}, {policy_id:POLICY[:policy_id],backend_id:''}].each do |policy|
      error('E_INPUT_CONTRACT',P.evaluate_expression(ast:ast,symbols:{},numeric_policy:policy))
    end
    error('E_RESERVED_SYMBOL',definitions({'sin'=>{source:'1',expected_type:'Scalar'}}))
    error('E_RESERVED_SYMBOL',expression('1',{'max'=>quantity(1)}))
    defs = {}
    100.times { |i| defs["v#{i}"] = {source:'1',expected_type:'Scalar'} }
    result = definitions(defs)
    assert result[:ok],result.inspect
    assert_equal 100,result[:value][:symbols].size
  end
  def test_exactness_is_not_recovered_through_a_condition_or_unused_branch
    result = expression('if(sin(pi/2)==1,1,2)')
    assert result[:ok],result.inspect
    refute result[:value][:numeric][:exact]
    error('E_INEXACT_DIVISION_INPUT',division('if(sin(pi/2)==1,1,2):1'))
    error('E_UNSUPPORTED_GRAMMAR',division('1{1}[32mm]:24mm',600))
    error('E_UNSUPPORTED_GRAMMAR',division('0:1[32mm]:24mm',600,'reference_points'))
  end
  def test_page_referenced_coordinates_and_resource_boundaries
    result = division('20mm:64mm:1:1:1:64mm:35mm',1000)
    assert_equal [20,84,Rational(1069,3),Rational(1886,3),901,965], result[:value][:internal_points].map { |p| n=p[:position][:numeric]; Rational(n[:numerator],n[:denominator]) }
    result = division('-200mm:1:-200mm',1000,'reference_points')
    assert_equal ['-200','1200'], result[:value][:internal_points].map { |p| p[:position][:numeric][:numerator] }
    assert_equal [1]*1000,lengths(division('1000{1}',1000))
    assert_equal 4096,P.parse_expression(source:' '*4095+'1',grammar_version:'jp-core-v1')[:value][:source].length
    assert_equal 1,number(expression('('*32+'1'+')'*32))
    error('E_RESOURCE_LIMIT',expression('1+'*600+'1'))
    result = expression("1+\u{1F9B5}")
    assert_equal({start:2,end:3},result[:diagnostics][0][:source_span])
    defs = {}
    1000.times { |i| defs["a#{i}"] = {source:'1',expected_type:'Scalar'} }
    result = definitions(defs)
    assert result[:ok],result.inspect
    assert_equal 1000,result[:value][:symbols].size
    defs = {'a'=>{source:'b',expected_type:'Scalar'},'b'=>{source:'c',expected_type:'Scalar'},'c'=>{source:'b',expected_type:'Scalar'}}
    assert_equal ['b','c','b'],definitions(defs)[:diagnostics][0][:details][:cycle]
  end
  def test_encoded_contract_fields_return_diagnostics
    error('E_INPUT_CONTRACT',expression('1',{'a'.encode('UTF-16LE')=>quantity(1)}))
    bad = quantity(1)
    bad[:numeric][:numerator] = '1'.encode('UTF-16LE')
    error('E_INPUT_CONTRACT',expression('a',{'a'=>bad}))
  end
end
