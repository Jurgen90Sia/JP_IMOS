require 'minitest/autorun'
require 'json'
require_relative '../../lib/jp_imos_pro/design/physical_checkpoint'
require_relative '../design/fixtures'
projection_path=File.expand_path('../../lib/jp_imos_pro/host/projection.rb',__dir__)
require projection_path if File.exist?(projection_path)

class HostProjectionTest < Minitest::Test
  include PhysicalDesignFixtures
  def build(state=physical_state,limits={})
    JPImosPro::Host::Projection.build(state:state,numeric_policy:policy,limits:limits)
  end
  def prepared(state=physical_state)
    r=build(state);assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def bounds(solid)
    points=solid['world_vertices'].map { |point| point.map { |v| JPImosPro::Zones::EngineBridge.rational(v) } }
    [3.times.map { |i| points.map { |v| v[i] }.min },3.times.map { |i| points.map { |v| v[i] }.max }]
  end
  def layered(n=1,d=10)
    state=physical_state
    state['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Synthetic surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    state['design']['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('far',n,d),surface('near',1,5)]
    state['part_policies'][0]['grain']['surfaces']=%w[u v]
    state
  end
  def test_entry_point_exists
    assert defined?(JPImosPro::Host::Projection),'missing pure Host::Projection'
  end
  def test_world_projection_translates_once_and_keeps_exact_top_basis
    state=physical_state;state['design']['project']['articles'][0]['origin']=[length(100),length(200),length(300)]
    p=prepared(state)
    assert_equal [[100,200,300],[118,760,1020]],bounds(p.plan['parts'][0]['solids'][0])
    assert_equal [[118,200,1002],[682,760,1020]],bounds(p.plan['parts'][2]['solids'][0])
    assert_equal [uuid(1000),uuid(1001),uuid(1002),uuid(1003)],p.plan['parts'].map { |v| v['part_id'] }
    assert_equal [1,1,1,1],p.plan['parts'].map { |v| v['solids'].size }
    state['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    assert_equal 882,bounds(prepared(state).plan['parts'][2]['solids'][0])[1][0]
  end
  def test_layers_keep_source_order_exact_offsets_and_volume
    p=prepared(layered);solids=p.plan['parts'][0]['solids']
    assert_equal [['substrate',nil],['surface',0],['surface',1]],solids.map { |v| [v['component'],v['source_index']] }
    assert_equal [Rational(1,5),Rational(91,5)],bounds(solids[0]).map { |v| v[0] }
    assert_equal [Rational(91,5),Rational(183,10)],bounds(solids[1]).map { |v| v[0] }
    assert_equal [0,Rational(1,5)],bounds(solids[2]).map { |v| v[0] }
    assert_equal p.snapshot['parts'][0]['part']['surface_layers'][0]['geometry']['finished_envelope_volume'],solids[1]['expected_volume']
    assert_equal 6,solids[1]['face_loops'].size
  end
  def test_empty_project_has_no_placeholder_solid
    state=physical_state;state['design']['project']['articles']=[];state['design']['construction_requests']=[];state['part_policies']=[]
    assert_equal [],prepared(state).plan['parts']
  end
  def test_profile_extent_and_world_coordinate_boundaries
    assert prepared(layered).plan
    error('E_HOST_GEOMETRY_UNREPRESENTABLE',build(layered(99,1000)))
    state=physical_state;state['design']['project']['articles'][0]['origin']=[length(999400),length(0),length(0)]
    assert_equal 1_000_000,bounds(prepared(state).plan['parts'][1]['solids'][0])[1][0]
    state['design']['project']['articles'][0]['origin'][0]=length(999400001,1000)
    error('E_HOST_GEOMETRY_UNREPRESENTABLE',build(state))
    state['design']['project']['articles'][0]['origin'][0]=length(-1000000001,1000)
    error('E_HOST_GEOMETRY_UNREPRESENTABLE',build(state))
  end
  def test_checkpoint_bytes_remain_identical_and_rebuild_same_snapshot
    state=physical_state;p=prepared(state)
    original=JPImosPro::Design::PhysicalCheckpoint.encode(state:state,numeric_policy:policy)
    assert original[:ok],original[:diagnostics].inspect
    # Captured from the unchanged baseline implementation at 3036d44, using
    # each real test backend. Other qualified backends still run roundtrip.
    baseline_digests={
      '2.7.8-x64-mingw32-Math'=>'50d7cf52a203d66dcea5a1534869d4d63ab0ebb53ef409e6d4fea4bf036e64e1',
      '3.2.9-x64-mingw-ucrt-Math'=>'15390ad562fde77adbf32c8de6e2331d7b23abc7d3686a968e307ebdced0cd32'}
    if baseline_digests.key?(policy[:backend_id])
      assert_equal baseline_digests.fetch(policy[:backend_id]),Digest::SHA256.hexdigest(original[:value])
    end
    budget=JPImosPro::ProjectCore::CoreBudget.new({})
    assert_equal original[:value],JPImosPro::ProjectCore::Codec.encode(p.checkpoint_record,budget)
    decoded=JPImosPro::Design::PhysicalCheckpoint.decode(source:original[:value],numeric_policy:policy)
    assert decoded[:ok],decoded[:diagnostics].inspect
    assert_equal p.snapshot,decoded[:value]['snapshot']
  end
  def test_owned_immutable_output_and_canonical_hash
    state=physical_state;p=prepared(state);again=prepared(state.to_a.reverse.to_h)
    assert_equal p.plan_sha256,again.plan_sha256
    assert_equal policy[:backend_id],p.plan['backend_id']
    assert_equal policy[:policy_id],p.plan['policy_id']
    assert_equal 'jp-host-unbanded-scratch-v1',p.plan['profile']
    assert p.frozen?
    assert p.plan['parts'][0]['solids'][0]['world_vertices'][0][0].frozen?
    assert p.state.frozen?
    assert p.checkpoint_record.frozen?
    refute state.frozen?
    state['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    assert_equal p.plan_sha256,again.plan_sha256
    assert_equal '600',p.state['design']['project']['articles'][0]['parameter_values']['W']['numeric']['numerator']
    assert_raises(NoMethodError) { p.class.new }
  end
  def test_derived_wire_inputs_and_unknown_source_fields_are_refused
    p=prepared
    error('E_SCHEMA_UNSUPPORTED',build(p.snapshot))
    state=physical_state;state['cached_snapshot']=p.snapshot
    error('E_INPUT_CONTRACT',build(state))
  end
  def test_trusted_resolution_guard_refuses_mixed_revision_or_policy
    p=prepared;api=JPImosPro::Host::Projection
    bad=Marshal.load(Marshal.dump(p.snapshot));bad['source_revision']=8
    result=JPImosPro::ProjectCore.boundary({}) do |budget|
      api.from_owned_resolution(state:p.state,snapshot:bad,numeric_policy:policy,budget:budget)
    end
    error('E_CHECKPOINT_MISMATCH',result)
    bad=Marshal.load(Marshal.dump(p.snapshot));bad['design_snapshot']['backend_id']='different'
    result=JPImosPro::ProjectCore.boundary({}) do |budget|
      api.from_owned_resolution(state:p.state,snapshot:bad,numeric_policy:policy,budget:budget)
    end
    error('E_NUMERIC_POLICY_CONFLICT',result)
  end
  def test_one_budget_refusal_has_no_partial_output_and_default_retry_succeeds
    result=build(physical_state,{work:100})
    error('E_RESOURCE_LIMIT',result)
    assert_equal 'unchanged',result[:metadata][:mutation_state]
    result=build
    assert result[:ok]
    assert_equal 'unchanged',result[:metadata][:mutation_state]
  end
end
