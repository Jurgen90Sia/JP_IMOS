require 'minitest/autorun'
require 'json'
require_relative '../../lib/jp_imos_pro/host/projection'
require_relative '../design/fixtures'
path=File.expand_path('../../lib/jp_imos_pro/host/document_codec.rb',__dir__)
require path if File.exist?(path)

class HostDocumentCodecTest < Minitest::Test
  include PhysicalDesignFixtures
  def projection(state=physical_state)
    r=JPImosPro::Host::Projection.build(state:state,numeric_policy:policy)
    assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def manifest(p)
    {'schema'=>'jpimos.host-manifest/1','plan_sha256'=>p.plan_sha256,'root_pid_hint'=>nil,
      'parts'=>p.plan['parts'].map do |part|
        {'part_id'=>part['part_id'],'container_pid_hint'=>nil,
          'solids'=>part['solids'].map { |s| {'component'=>s['component'],'source_index'=>s['source_index'],'pid_hint'=>nil} }}
      end}
  end
  def encode(state=physical_state,m=nil,root=uuid(2000),limits={})
    m||=manifest(projection(state))
    JPImosPro::Host::DocumentCodec.encode(state:state,root_id:root,acceptance_id:uuid(2001),manifest:m,numeric_policy:policy,limits:limits)
  end
  def encoded(state=physical_state)
    r=encode(state);assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def decode(source,p=policy,limits={})
    JPImosPro::Host::DocumentCodec.decode(source:source,numeric_policy:p,limits:limits)
  end
  def canonical(value)
    case value
    when Hash then value.keys.sort.to_h { |k| [k,canonical(value[k])] }
    when Array then value.map { |v| canonical(v) }
    else value
    end
  end
  def repair(record)
    body=record.reject { |k,_| k=='content_sha256' }
    record['content_sha256']=Digest::SHA256.hexdigest(JSON.generate(canonical(body)))
    JSON.generate(record)
  end
  def test_entry_point_exists
    assert defined?(JPImosPro::Host::DocumentCodec),'missing host document codec'
  end
  def test_roundtrip_owns_closed_document_and_rebuilds_source_projection
    source=encoded;r=decode(source);assert r[:ok],r[:diagnostics].inspect
    value=r[:value];doc=value.document
    assert_equal %w[acceptance_id checkpoint content_sha256 profile project_id projection root_id schema scope],doc.keys.sort
    assert_equal 'controlled_scratch',doc['scope']
    assert_equal 'jp-host-unbanded-scratch-v1',doc['profile']
    assert_equal uuid(1),doc['project_id']
    assert_equal uuid(2000),doc['root_id']
    assert_equal projection.plan,value.projection.plan
    assert_equal value.projection.plan_sha256,doc['projection']['plan_sha256']
    assert_equal source,encode(value.projection.state,doc['projection'])[:value]
    assert_equal 'unchanged',r[:metadata][:mutation_state]
    assert value.frozen?
    assert doc['checkpoint']['state'].frozen?
    assert_raises(NoMethodError) { value.class.new }
    refute doc.key?('snapshot')
  end
  def test_pid_uint64_strings_and_nulls_are_hints_not_identity
    p=projection;m=manifest(p);m['root_pid_hint']='18446744073709551615'
    m['parts'][0]['container_pid_hint']='1';m['parts'][0]['solids'][0]['pid_hint']='9007199254740993'
    r=encode(physical_state,m);assert r[:ok],r[:diagnostics].inspect
    d=decode(r[:value]);assert d[:ok],d[:diagnostics].inspect
    assert_equal '18446744073709551615',d[:value].document['projection']['root_pid_hint']
    assert_equal '9007199254740993',d[:value].document['projection']['parts'][0]['solids'][0]['pid_hint']
    assert_equal p.plan_sha256,d[:value].projection.plan_sha256
    ['0','01','-1','1.0','18446744073709551616',1,1.0,true,'9'*100].each do |hint|
      m['root_pid_hint']=hint
      error('E_INPUT_CONTRACT',encode(physical_state,m))
    end
  end
  def test_closed_shapes_and_unknown_versions_are_refused
    base=JSON.parse(encoded)
    [['schema','other'],['profile','other']].each do |key,value|
      d=Marshal.load(Marshal.dump(base));d[key]=value
      error('E_SCHEMA_UNSUPPORTED',decode(repair(d)))
    end
    d=Marshal.load(Marshal.dump(base));d['scope']='production'
    error('E_INPUT_CONTRACT',decode(repair(d)))
    [[],%w[projection],%w[projection parts 0],%w[projection parts 0 solids 0]].each do |path|
      d=Marshal.load(Marshal.dump(base));target=d
      path.each { |k| target=target.is_a?(Array) ? target[k.to_i] : target[k] }
      target['extra']=true
      error('E_INPUT_CONTRACT',decode(repair(d)))
    end
    d=Marshal.load(Marshal.dump(base));d['projection']['parts'][0].delete('container_pid_hint')
    error('E_INPUT_CONTRACT',decode(repair(d)))
    d=Marshal.load(Marshal.dump(base));d['projection']['schema']='other'
    error('E_SCHEMA_UNSUPPORTED',decode(repair(d)))
  end
  def test_missing_duplicate_reordered_or_extra_part_component_coverage_fails
    base=JSON.parse(encoded)
    mutations=[
      ->(m) { m['parts'].pop },
      ->(m) { m['parts'] << m['parts'][0].dup },
      ->(m) { m['parts'].reverse! },
      ->(m) { m['parts'][0]['part_id']=uuid(9999) },
      ->(m) { m['parts'][0]['solids']=[] },
      ->(m) { m['parts'][0]['solids'] *= 2 },
      ->(m) { m['parts'][0]['solids'][0]['component']='surface' },
      ->(m) { m['parts'][0]['solids'][0]['source_index']=0 }]
    mutations.each do |change|
      d=Marshal.load(Marshal.dump(base));change.call(d['projection'])
      error('E_HOST_OWNERSHIP_CONFLICT',decode(repair(d)))
    end
  end
  def test_repaired_checksums_do_not_authorize_stale_plan_project_or_source
    base=JSON.parse(encoded)
    d=Marshal.load(Marshal.dump(base));d['projection']['plan_sha256']='0'*64
    error('E_HOST_GEOMETRY_CONFLICT',decode(repair(d)))
    d=Marshal.load(Marshal.dump(base));d['project_id']=uuid(99)
    error('E_HOST_OWNERSHIP_CONFLICT',decode(repair(d)))
    d=Marshal.load(Marshal.dump(base));d['checkpoint']['state']['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    repair(d['checkpoint'])
    error('E_CHECKPOINT_MISMATCH',decode(repair(d)))
    # A completely valid new source/checkpoint still cannot use the old plan.
    state=physical_state;state['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    d=Marshal.load(Marshal.dump(base));d['checkpoint']=projection(state).checkpoint_record
    error('E_HOST_GEOMETRY_CONFLICT',decode(repair(d)))
    d=Marshal.load(Marshal.dump(base));d['acceptance_id']=uuid(99)
    error('E_CHECKPOINT_INTEGRITY',decode(JSON.generate(d)))
  end
  def test_empty_document_requires_null_root_and_no_hint
    state=physical_state;state['design']['project']['articles']=[];state['design']['construction_requests']=[];state['part_policies']=[]
    p=projection(state);m=manifest(p)
    r=encode(state,m,nil);assert r[:ok],r[:diagnostics].inspect
    d=decode(r[:value]);assert d[:ok],d[:diagnostics].inspect
    assert_nil d[:value].document['root_id']
    assert_empty d[:value].projection.plan['parts']
    error('E_HOST_OWNERSHIP_CONFLICT',encode(state,m))
    m['root_pid_hint']='1'
    error('E_HOST_OWNERSHIP_CONFLICT',encode(state,m,nil))
    error('E_HOST_OWNERSHIP_CONFLICT',encode(physical_state,nil,nil))
  end
  def test_backend_mismatch_has_checkpoint_pointer_and_no_partial_value
    r=decode(encoded,{policy_id:policy[:policy_id],backend_id:'different'})
    error('E_NUMERIC_POLICY_CONFLICT',r)
    assert_equal '/checkpoint/verification',r[:diagnostics][0][:json_pointer]
    assert_equal 'unchanged',r[:metadata][:mutation_state]
  end
  def test_duplicate_json_keys_resource_refusal_and_fresh_retry
    error('E_DUPLICATE_JSON_KEY',decode('{"schema":"a","schema":"b"}'))
    source=encoded
    error('E_RESOURCE_LIMIT',decode(source,policy,{work:100}))
    error('E_RESOURCE_LIMIT',encode(physical_state,nil,uuid(2000),{work:100}))
    assert decode(source)[:ok]
    error('E_INPUT_CONTRACT',decode('null'))
  end
  def test_manifest_is_copied_and_key_reorder_is_canonical
    m=manifest(projection);before=Marshal.dump(m)
    r=encode(physical_state,m);assert r[:ok],r[:diagnostics].inspect
    refute m.frozen?;assert_equal before,Marshal.dump(m)
    reordered=m.to_a.reverse.to_h
    assert_equal r[:value],encode(physical_state,reordered)[:value]
    m['parts'][0]['part_id']=uuid(99)
    assert_equal uuid(1000),JSON.parse(r[:value])['projection']['parts'][0]['part_id']
  end
  def test_layer_manifest_covers_exact_source_indices_and_shared_internal_paths
    state=physical_state
    state['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Synthetic surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    state['design']['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('far',1,10),surface('near',1,5)]
    state['part_policies'][0]['grain']['surfaces']=%w[u v]
    p=projection(state);m=manifest(p)
    source=encode(state,m)[:value];refute_nil source
    r=decode(source);assert r[:ok],r[:diagnostics].inspect
    assert_equal [['substrate',nil],['surface',0],['surface',1]],r[:value].document['projection']['parts'][0]['solids'].map { |s| [s['component'],s['source_index']] }
    budget=JPImosPro::ProjectCore::CoreBudget.new({})
    assert_equal source,JPImosPro::Host::DocumentCodec.encode_owned(projection:p,root_id:uuid(2000),acceptance_id:uuid(2001),manifest:m,budget:budget)
    decoded=JPImosPro::Host::DocumentCodec.decode_with_budget(source:source,numeric_policy:policy,budget:JPImosPro::ProjectCore::CoreBudget.new({}))
    assert_equal p.plan_sha256,decoded.projection.plan_sha256
    m['parts'][0]['solids'].rotate!
    error('E_HOST_OWNERSHIP_CONFLICT',encode(state,m))
    d=JSON.parse(source);d['checkpoint']['extra']=true;repair(d['checkpoint'])
    r=decode(repair(d));error('E_INPUT_CONTRACT',r)
    assert_equal '/checkpoint/extra',r[:diagnostics][0][:json_pointer]
  end
  def test_string_budget_and_missing_fields_have_bounded_refusals
    source=encoded
    error('E_RESOURCE_LIMIT',decode(source,policy,{json_bytes:source.bytesize-1}))
    d=JSON.parse(source);d.delete('root_id')
    error('E_INPUT_CONTRACT',decode(repair(d)))
    d=JSON.parse(source);d['root_id']='invalid'
    error('E_INPUT_CONTRACT',decode(repair(d)))
    d=JSON.parse(source);d['projection']['plan_sha256']='xyz'
    error('E_INPUT_CONTRACT',decode(repair(d)))
    d=JSON.parse(source);d['projection']['parts'][0]['solids'][0].delete('pid_hint')
    error('E_INPUT_CONTRACT',decode(repair(d)))
  end
end
