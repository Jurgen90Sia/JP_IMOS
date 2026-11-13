require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'

class CoreCodecTest < Minitest::Test
  C = JPImosPro::ProjectCore
  def parse(source, limits = {})
    C::Codec.parse(source, C::CoreBudget.new(limits))
  end
  def fault(code, source, pointer = nil, limits = {})
    e = assert_raises(C::Fault) { parse(source, limits) }
    assert_equal code, e.code
    assert_equal pointer, e.json_pointer if pointer
    e
  end
  def test_duplicate_decoded_keys_are_not_overwritten
    fault('E_DUPLICATE_JSON_KEY', '{"revision":1,"revi\u0073ion":2}', '/revision')
    fault('E_DUPLICATE_JSON_KEY', '{"a":[{"x":1,"x":2}]}', '/a/0/x')
    fault('E_DUPLICATE_JSON_KEY', '{"a/b":{"~":1,"~":2}}', '/a~1b/~0')
    fault('E_DUPLICATE_JSON_KEY', '{"z":0,"z":1,"a":0,"a":1}', '/a')
    assert_equal({'a'=>1,'b'=>{'a'=>2}}, parse('{"a":1,"b":{"a":2}}'))
  end
  def test_json_boundary_is_bounded_and_strict
    ['NaN','Infinity','{"a":}',"\xFF".b.force_encoding('UTF-8')].each { |s| fault('E_INPUT_CONTRACT',s) }
    fault('E_INPUT_CONTRACT', '{}'.encode('UTF-16LE'))
    fault('E_INPUT_CONTRACT', nil)
    assert_equal({},parse(' '*(1_048_576-2)+'{}'))
    fault('E_RESOURCE_LIMIT',' '*1_048_575+'{}')
    assert_equal [],parse('[]')
    assert parse('['*64+'0'+']'*64)
    fault('E_RESOURCE_LIMIT','['*65+'0'+']'*65)
    fault('E_RESOURCE_LIMIT','{}',nil,{json_bytes:1})
    fault('E_INPUT_CONTRACT','{}',nil,{json_bytes:1_048_577})
    fault('E_INPUT_CONTRACT','{}',nil,{'json_bytes'=>100})
    fault('E_RESOURCE_LIMIT','[1,2,3]',nil,{work:2})
  end
end
