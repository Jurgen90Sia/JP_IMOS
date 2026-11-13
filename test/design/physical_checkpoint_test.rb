require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/design/physical_state'
require_relative '../../lib/jp_imos_pro/design/physical_checkpoint'
require_relative 'fixtures'
class PhysicalCheckpointTest < Minitest::Test
  include PhysicalDesignFixtures
  def encode(state=physical_state,limits={})
    JPImosPro::Design::PhysicalCheckpoint.encode(state:state,numeric_policy:policy,limits:limits)
  end
  def decode(source,p=policy,limits={})
    JPImosPro::Design::PhysicalCheckpoint.decode(source:source,numeric_policy:p,limits:limits)
  end
  def canonical(value)
    case value
    when Hash then value.keys.sort.to_h { |key| [key,canonical(value[key])] }
    when Array then value.map { |v| canonical(v) }
    else value
    end
  end
  def repair(data)
    body=data.reject { |key,_| key=='content_sha256' }
    data['content_sha256']=Digest::SHA256.hexdigest(JSON.generate(canonical(body)))
    JSON.generate(data)
  end
  def test_round_trip_rebuilds_the_same_source_and_snapshot_without_storing_geometry
    encoded=encode
    assert encoded[:ok],encoded[:diagnostics].inspect
    data=JSON.parse(encoded[:value])
    assert_equal %w[content_sha256 schema state verification],data.keys.sort
    assert_equal 'jpimos.physical-checkpoint/1',data['schema']
    refute data.key?('snapshot')
    r=decode(encoded[:value])
    assert r[:ok],r[:diagnostics].inspect
    expected=JPImosPro::Design::PhysicalState.resolve(state:physical_state,numeric_policy:policy)[:value]
    assert_equal expected['state'],r[:value]['state']
    assert_equal expected['snapshot'],r[:value]['snapshot']
    assert_equal 7,r[:value]['verification']['revision']
    assert_equal encoded[:value],encode(r[:value]['state'])[:value]
    assert r[:value]['verification'].frozen?
    assert r[:value]['snapshot']['parts'][0].frozen?
  end
  def test_checksum_and_canonical_source_ordering
    first=encode[:value]
    assert_equal first,encode(physical_state.to_a.reverse.to_h)[:value]
    data=JSON.parse(first)
    assert_equal data['content_sha256'],JSON.parse(repair(data))['content_sha256']
    data['state']['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    error('E_CHECKPOINT_INTEGRITY',decode(JSON.generate(data)))
  end
  def test_repaired_checksum_does_not_bypass_rebuilt_verification
    %w[project_id revision state_sha256 catalog_sha256 snapshot_sha256].each do |field|
      data=JSON.parse(encode[:value])
      data['verification'][field]=case field
      when 'project_id' then uuid(99)
      when 'revision' then 8
      else '0'*64
      end
      r=decode(repair(data))
      error('E_CHECKPOINT_MISMATCH',r)
      assert_equal '/verification/'+field,r[:diagnostics][0][:json_pointer]
    end
    data=JSON.parse(encode[:value]);data['state']['part_policies'][0]['grain']['substrate']='v'
    error('E_CHECKPOINT_MISMATCH',decode(repair(data)))
  end
  def test_changed_backend_and_invalid_policy_are_not_silently_rebound
    source=encode[:value]
    error('E_NUMERIC_POLICY_CONFLICT',decode(source,policy.merge(backend_id:policy[:backend_id]+'-other')))
    error('E_INPUT_CONTRACT',decode(source,{}))
    data=JSON.parse(source);data['verification']['backend_id']+='-other'
    error('E_NUMERIC_POLICY_CONFLICT',decode(repair(data)))
  end
  def test_closed_schema_derived_sources_and_duplicate_keys_are_refused
    data=JSON.parse(encode[:value]);data['schema']='jpimos.physical-checkpoint/2'
    error('E_SCHEMA_UNSUPPORTED',decode(repair(data)))
    data=JSON.parse(encode[:value]);data['snapshot']={}
    error('E_INPUT_CONTRACT',decode(repair(data)))
    data=JSON.parse(encode[:value]);data['verification']['accepted']=true
    error('E_INPUT_CONTRACT',decode(repair(data)))
    error('E_DUPLICATE_JSON_KEY',decode('{"schema":"a","schema":"b"}'))
    snapshot=JPImosPro::Design::PhysicalState.resolve(state:physical_state,numeric_policy:policy)[:value]['snapshot']
    error('E_SCHEMA_UNSUPPORTED',encode(snapshot))
  end
  def test_invalid_verification_values_are_typed_errors
    data=JSON.parse(encode[:value]);data['verification']['state_sha256']='bad'
    error('E_INPUT_CONTRACT',decode(repair(data)))
    data=JSON.parse(encode[:value]);data['verification']['revision']=-1
    error('E_INPUT_CONTRACT',decode(repair(data)))
    data=JSON.parse(encode[:value]);data['verification']['project_id']='bad'
    error('E_INPUT_CONTRACT',decode(repair(data)))
  end
  def test_callers_are_not_mutated_or_frozen_and_rebuilt_values_are_owned
    state=physical_state;before=Marshal.dump(state)
    encoded=encode(state)
    assert encoded[:ok],encoded[:diagnostics].inspect
    assert_equal before,Marshal.dump(state)
    refute state.frozen?
    source=encoded[:value].dup
    r=decode(source)
    assert r[:ok],r[:diagnostics].inspect
    refute source.frozen?
    source.replace('{}')
    state['part_policies'][0]['grain']['substrate']='v'
    assert_equal 'u',r[:value]['state']['part_policies'][0]['grain']['substrate']
    assert r[:value].frozen?
  end
  def test_resource_failures_return_no_partial_checkpoint_or_reopened_state
    source=encode[:value]
    error('E_RESOURCE_LIMIT',encode(physical_state,{work:1}))
    r=decode(source,policy,{work:48_000})
    error('E_RESOURCE_LIMIT',r)
    assert_nil r[:value]
    assert decode(source)[:ok]
  end
end
