require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/design'
require_relative '../../lib/jp_imos_pro/design/physical_state'
require_relative 'fixtures'

class PhysicalStateTest < Minitest::Test
  include DesignFixtures
  def physical_state
    {'schema'=>'jpimos.physical-design/1','design'=>design_state,
      'catalog'=>{'schema'=>'jpimos.material-catalog/1','entries'=>[
        {'id'=>uuid(900),'version'=>1,'label'=>'Synthetic panel','category'=>'panel','provenance'=>{'kind'=>'user_declared','note'=>''}}]},
      'part_policies'=>%w[left right top bottom].each_with_index.map do |role,i|
        {'id'=>uuid(1000+i),'article_instance_id'=>uuid(4),'role'=>role,
          'grain'=>{'substrate'=>'u','surfaces'=>[]},'edges'=>%w[u_min u_max v_min v_max].to_h { |edge| [edge,{'kind'=>'none'}] }}
      end}
  end
  def resolve(state=physical_state,limits={})
    JPImosPro::Design::PhysicalState.resolve(state:state,numeric_policy:policy,limits:limits)
  end
  def prepare(before,after,expected=7,limits={})
    JPImosPro::Design::PhysicalState.prepare_revision(current:before,replacement:after,expected_revision:expected,numeric_policy:policy,limits:limits)
  end
  def test_snapshot_parts_are_bound_to_the_owned_project_catalog_and_source_geometry
    r=resolve
    assert r[:ok],r[:diagnostics].inspect
    value=r[:value];s=value['snapshot']
    assert_equal 7,s['source_revision']
    assert_equal 'prepared_registry_bound_user_declared',s['status']
    assert_equal 4,s['parts'].size
    assert_equal %w[left right top bottom],s['parts'].map { |p| p['part']['occurrence_ref']['role'] }
    assert_equal s['design_snapshot']['state_sha256'],s['material_report']['state_sha256']
    refute_equal s['state_sha256'],s['material_report']['state_sha256']
    s['parts'].each do |entry|
      assert_equal 7,entry['source_binding']['source_revision']
      assert_equal uuid(1),entry['source_binding']['project_id']
      assert_equal s['state_sha256'],entry['source_binding']['state_sha256']
      assert_equal s['catalog_sha256'],entry['source_binding']['catalog_sha256']
      assert_equal 'prepared_unbound_part',entry['part']['status']
      assert_equal uuid(3),entry['part']['owner_zone_ref']['authored_zone_id']
    end
    assert_equal '564',s['parts'][2]['part']['finished_dimensions'][0]['numeric']['numerator']
    assert value['state'].frozen?
    assert s['parts'][0]['source_binding'].frozen?
  end
  def test_resize_prepares_one_revision_and_keeps_part_identity
    before=physical_state;after=physical_state
    after['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    r=prepare(before,after)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 7,r[:value]['base_revision']
    assert_equal 8,r[:value]['next_revision']
    assert_equal 8,r[:value]['state']['design']['project']['revision']
    s=r[:value]['snapshot']
    assert_equal 8,s['source_revision']
    assert_equal 8,s['material_report']['source_revision']
    assert_equal s['design_snapshot']['state_sha256'],s['material_report']['state_sha256']
    assert_equal [8],s['parts'].map { |p| p['source_binding']['source_revision'] }.uniq
    assert_equal [uuid(1000),uuid(1001),uuid(1002),uuid(1003)],s['parts'].map { |p| p['part']['id'] }
    assert_equal '764',s['parts'][2]['part']['finished_dimensions'][0]['numeric']['numerator']
    assert_equal 7,before['design']['project']['revision']
    assert_equal 7,after['design']['project']['revision']
  end
  def test_grain_only_edit_is_semantic_and_changes_the_owner_hash
    before=physical_state;after=physical_state
    after['part_policies'][0]['grain']['substrate']='v'
    r=prepare(before,after)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 8,r[:value]['next_revision']
    assert_equal 'v',r[:value]['snapshot']['parts'][0]['part']['grain']['substrate']
    refute_equal resolve(before)[:value]['snapshot']['state_sha256'],r[:value]['snapshot']['state_sha256']
  end
  def test_catalog_versions_are_immutable_and_new_pin_edits_share_the_revision
    before=physical_state;after=physical_state
    after['catalog']['entries'][0]['label']='Changed'
    error('E_MATERIAL_VERSION_CONFLICT',prepare(before,after))
    after['catalog']['entries'][0]['version']=2
    after['design']['construction_requests'][0]['panels'].each_value { |char| char['material_ref']['version']=2 }
    r=prepare(before,after)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 8,r[:value]['next_revision']
    assert_equal [2],r[:value]['snapshot']['material_report']['bindings'].map { |b| b['material']['version'] }.uniq
    assert_equal [2],r[:value]['snapshot']['parts'].map { |p| p['part']['characteristic']['material_ref']['version'] }.uniq
  end
  def test_missing_duplicate_unknown_and_reassigned_policies_fail
    data=physical_state;data['part_policies'].pop
    error('E_REFERENCE_MISSING',resolve(data))
    data=physical_state;data['part_policies'][1]['id']=data['part_policies'][0]['id']
    error('E_DUPLICATE_ID',resolve(data))
    data=physical_state;data['part_policies'][0]['article_instance_id']=uuid(99)
    error('E_REFERENCE_MISSING',resolve(data))
    before=physical_state;after=physical_state;after['part_policies'][0]['id']=uuid(2000)
    error('E_PART_IDENTITY_CONFLICT',prepare(before,after))
    after=physical_state;after['part_policies'][0]['id'],after['part_policies'][1]['id']=after['part_policies'][1]['id'],after['part_policies'][0]['id']
    error('E_PART_IDENTITY_CONFLICT',prepare(before,after))
  end
  def test_material_and_surface_policy_coverage_are_checked_before_geometry
    data=physical_state;data['catalog']['entries']=[]
    error('E_MATERIAL_REFERENCE_UNRESOLVED',resolve(data))
    data=physical_state
    data['design']['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('near',1)]
    error('E_INPUT_CONTRACT',resolve(data))
    data['part_policies'][0]['grain']['surfaces']=['u']
    error('E_MATERIAL_REFERENCE_UNRESOLVED',resolve(data))
    data['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Synthetic surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    r=resolve(data)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal '19',r[:value]['snapshot']['parts'][0]['part']['finished_dimensions'][2]['numeric']['numerator']
    assert_equal '563',r[:value]['snapshot']['parts'][2]['part']['finished_dimensions'][0]['numeric']['numerator']
    assert_equal 5,r[:value]['snapshot']['material_report']['bindings'].size
  end
  def test_codecs_own_authoring_and_reject_derived_inputs_and_duplicate_keys
    api=JPImosPro::Design::PhysicalState
    data=physical_state
    encoded=api.encode(state:data)
    assert encoded[:ok],encoded[:diagnostics].inspect
    decoded=api.decode(source:encoded[:value])
    assert decoded[:ok],decoded[:diagnostics].inspect
    assert_equal encoded[:value],api.encode(state:decoded[:value])[:value]
    error('E_SCHEMA_UNSUPPORTED',api.validate(state:design_state))
    error('E_SCHEMA_UNSUPPORTED',api.validate(state:resolve[:value]['snapshot']))
    error('E_DUPLICATE_JSON_KEY',api.decode(source:'{"schema":"jpimos.physical-design/1","schema":"wrong"}'))
    data=physical_state;data['part_policies'][0]['frame']={}
    error('E_INPUT_CONTRACT',api.validate(state:data))
  end
  def test_stale_noop_reordered_and_exhausted_revisions_fail_without_side_effects
    before=physical_state;after=physical_state
    error('E_REVISION_CONFLICT',prepare(before,after,6))
    error('E_NO_CHANGE',prepare(before,after))
    after['part_policies'].reverse!
    error('E_NO_CHANGE',prepare(before,after))
    before['design']['project']['revision']=9_007_199_254_740_991
    after['design']['project']['revision']=9_007_199_254_740_991
    error('E_REVISION_EXHAUSTED',prepare(before,after,9_007_199_254_740_991))
  end
  def test_caller_mutation_cannot_change_frozen_preparation_or_canonical_hashes
    data=physical_state;original=Marshal.dump(data)
    first=resolve(data)
    assert first[:ok],first[:diagnostics].inspect
    assert_equal original,Marshal.dump(data)
    refute data.frozen?
    second=resolve(data.to_a.reverse.to_h)
    assert_equal first[:value]['snapshot']['content_sha256'],second[:value]['snapshot']['content_sha256']
    data['part_policies'][0]['grain']['substrate']='v'
    assert_equal 'u',first[:value]['snapshot']['parts'][0]['part']['grain']['substrate']
    refute_equal first[:value]['snapshot']['state_sha256'],resolve(data)[:value]['snapshot']['state_sha256']
  end
  def test_empty_projects_and_resource_exhaustion_are_atomic
    data=physical_state
    data['design']['project']['articles']=[];data['design']['construction_requests']=[];data['part_policies']=[]
    r=resolve(data)
    assert r[:ok],r[:diagnostics].inspect
    assert_empty r[:value]['snapshot']['parts']
    error('E_RESOURCE_LIMIT',resolve(physical_state,{work:1}))
    assert resolve[:ok]
  end
  def test_transition_diagnostics_point_to_submitted_array_positions_after_normalization
    before=physical_state;after=physical_state
    after['part_policies'].reverse!
    after['part_policies'][0]['id']=uuid(2000)
    r=prepare(before,after)
    error('E_PART_IDENTITY_CONFLICT',r)
    assert_equal '/replacement/part_policies/0/id',r[:diagnostics][0][:json_pointer]
    before=physical_state
    before['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Unused surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    after=Marshal.load(Marshal.dump(before))
    after['catalog']['entries'].reverse!
    after['catalog']['entries'][1]['label']='Changed'
    r=prepare(before,after)
    error('E_MATERIAL_VERSION_CONFLICT',r)
    assert_equal '/replacement/catalog/entries/1',r[:diagnostics][0][:json_pointer]
  end
  def test_hashes_cover_the_complete_authoring_and_snapshot_payload
    r=resolve
    assert r[:ok],r[:diagnostics].inspect
    canon=lambda { |x| x.is_a?(Hash) ? x.keys.sort.to_h { |k| [k,canon.call(x[k])] } : x.is_a?(Array) ? x.map { |v| canon.call(v) } : x }
    s=r[:value]['snapshot']
    assert_equal Digest::SHA256.hexdigest(JSON.generate(canon.call(r[:value]['state']))),s['state_sha256']
    body=s.reject { |k,_| k=='content_sha256' }
    assert_equal Digest::SHA256.hexdigest(JSON.generate(canon.call(body))),s['content_sha256']
    data=physical_state
    data['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Unused surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    other=resolve(data)[:value]['snapshot']
    refute_equal s['state_sha256'],other['state_sha256']
    refute_equal s['catalog_sha256'],other['catalog_sha256']
  end
  def test_composition_spends_one_budget_without_publishing_a_partial_snapshot
    assert JPImosPro::Design::PhysicalState.validate(state:physical_state,limits:{work:16_000})[:ok]
    result=resolve(physical_state,{work:48_000})
    error('E_RESOURCE_LIMIT',result)
    assert_nil result[:value]
    assert_equal result[:diagnostics],resolve(physical_state,{work:48_000})[:diagnostics]
    assert resolve[:ok]
  end
end
