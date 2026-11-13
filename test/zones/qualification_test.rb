require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'
class ZoneQualificationTest < Minitest::Test
  include ZoneFixtures
  C=JPImosPro::ProjectCore
  def test_many_valid_expressions_use_one_global_budget_and_fail_atomically
    doc=layers(10)
    doc['definitions'][0]['zones'][0]['layout']['placements'].each do |p|
      %w[u v w].each do |axis|
        p['bounds'][axis][0]['source']=(['0mm']*20).join('+')
        p['bounds'][axis][1]['source'] += '+0mm'*19
      end
    end
    assert C.encode_document(document:doc,limits:{work:10000})[:ok], 'validation alone must fit'
    r=resolve(doc,{work:10000})
    error('E_RESOURCE_LIMIT',r)
    assert_equal r[:diagnostics],resolve(doc,{work:10000})[:diagnostics]
    assert_equal 11,zones(resolve(doc)).size
    assert_equal 3,zones(resolve(layers)).size
    refute doc.frozen?
  end
  def test_lexical_error_selection_in_independent_layers_and_reused_occurrences
    doc=layers(12)
    [2,10].each { |i| doc['definitions'][0]['zones'][0]['layout']['placements'][i]['bounds']['u'][0]['source']='missing' }
    doc['articles'] << Marshal.load(Marshal.dump(doc['articles'][0])).merge('id'=>uuid(2))
    r=resolve(doc)
    error('E_UNKNOWN_SYMBOL',r)
    assert_equal '/definitions/0/zones/0/layout/placements/10/bounds/u/0/source',r[:diagnostics][0][:json_pointer]
    assert_equal uuid(2),r[:diagnostics][0][:entity_ref]['article_instance_id']
    doc['definitions'][0]['zones'][0]['children'][0]['zone_id']=uuid(999)
    error('E_REFERENCE_MISSING',resolve(doc))
  end
  def test_runtime_metadata_does_not_freeze_or_accept_invalid_backend_strings
    p=policy
    r=C.resolve_zones(document:valid_document,numeric_policy:p)
    assert r[:ok]
    refute p.frozen?
    refute p[:backend_id].frozen?
    assert_equal p[:backend_id],r[:value]['backend_id']
    [nil,false,{},policy.merge(backend_id:'x'.encode('UTF-16LE')),policy.merge(backend_id:"\xFF".b.force_encoding('UTF-8'))].each do |bad|
      error('E_INPUT_CONTRACT',C.resolve_zones(document:valid_document,numeric_policy:bad))
    end
    callback=Object.new
    def callback.tick(*)
      raise 'untrusted callback executed'
    end
    assert C.resolve_zones(document:valid_document,numeric_policy:policy.merge(shared_counter:callback))[:ok]
    hostile=Object.new
    def hostile.==(_other)
      raise 'untrusted equality callback executed'
    end
    error('E_INPUT_CONTRACT',C.resolve_zones(document:valid_document,numeric_policy:policy.merge(policy_id:hostile)))
  end
  def test_real_engine_limits_remain_active_in_zone_resolution
    error('E_RESOURCE_LIMIT',resolve(partition(valid_document,'1001{1}')))
    error('E_RESOURCE_LIMIT',resolve(partition(valid_document,'('*33+'1'+')'*33+':1')))
    doc=layers
    doc['definitions'][0]['zones'][0]['layout']['placements'][0]['bounds']['u'][0]['source']='(2^3)mm'
    error('E_UNSUPPORTED_GRAMMAR',resolve(doc))
    doc=layers
    doc['definitions'][0]['zones'][0]['layout']['placements'][0]['bounds']['u'][0]['source']='Y'
    error('E_UNKNOWN_SYMBOL',resolve(doc))
  end
  def test_backend_metadata_cannot_bypass_the_request_byte_limit
    assert resolve(valid_document,{json_bytes:4096})[:ok]
    r=C.resolve_zones(document:valid_document,numeric_policy:policy.merge(backend_id:'a'*5000),limits:{json_bytes:4096})
    error('E_RESOURCE_LIMIT',r)
  end
end
