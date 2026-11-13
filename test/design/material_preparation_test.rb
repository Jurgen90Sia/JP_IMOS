require 'minitest/autorun'
require 'digest'
require 'json'
require_relative '../../lib/jp_imos_pro/materials/catalog'
require_relative '../../lib/jp_imos_pro/design/material_preparation'
require_relative 'fixtures'

class MaterialPreparationTest < Minitest::Test
  include DesignFixtures
  def catalog
    {'schema'=>'jpimos.material-catalog/1','entries'=>[
      {'id'=>uuid(900),'version'=>1,'label'=>'Panel','category'=>'panel','provenance'=>{'kind'=>'user_declared','note'=>'Synthetic fixture'}}]}
  end
  def prepare(state=design_state,data=catalog,limits={})
    JPImosPro::Design::MaterialPreparation.prepare(state:state,catalog:data,numeric_policy:policy,limits:limits)
  end
  def test_geometry_and_reference_report_bind_the_same_owned_revision
    r=prepare
    assert r[:ok],r[:diagnostics].inspect
    value=r[:value]
    assert_equal 'jpimos.material-bound-design/1',value['schema']
    assert_equal 7,value['snapshot']['source_revision']
    assert_equal value['snapshot']['state_sha256'],value['material_report']['state_sha256']
    assert_equal 4,value['material_report']['bindings'].size
    panels=value['snapshot']['carcass_previews'][0]['panels']
    assert_equal %w[left right top bottom],panels.map { |p| p['role'] }
    assert_equal '564',panels[2]['face_size'][0]['numeric']['numerator']
    assert_equal 'registry_resolved_user_declared',value['material_report']['status']
    assert_equal 'caller_declared_unverified_catalog',panels[0]['characteristic']['material_reference_status']
    assert_equal 'user_declared',value['catalog']['entries'][0]['provenance']['kind']
    assert value.frozen?
    assert value['catalog']['entries'][0]['provenance']['note'].frozen?
  end
  def test_missing_pin_and_wrong_category_fail_atomically
    data=catalog;data['entries'][0]['version']=2
    r=prepare(design_state,data)
    error('E_MATERIAL_REFERENCE_UNRESOLVED',r)
    assert_equal '/construction_requests/0/panels/left/material_ref',r[:diagnostics][0][:json_pointer]
    data=catalog;data['entries'][0]['category']='surface'
    error('E_MATERIAL_CATEGORY_MISMATCH',prepare(design_state,data))
    refute data.frozen?
  end
  def test_dimensional_surface_pin_must_resolve_before_geometry_is_returned
    state=design_state
    state['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('near',1)]
    error('E_MATERIAL_REFERENCE_UNRESOLVED',prepare(state))
    data=catalog
    data['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    r=prepare(state,data)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 5,r[:value]['material_report']['bindings'].size
    assert_equal '19',r[:value]['snapshot']['carcass_previews'][0]['panels'][0]['finished_thickness']['numeric']['numerator']
  end
  def test_inputs_remain_mutable_without_changing_prepared_values
    state=design_state;data=catalog
    before=Marshal.dump([state,data])
    r=prepare(state,data)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal before,Marshal.dump([state,data])
    refute state.frozen?
    refute data.frozen?
    data['entries'][0]['label'].replace('Changed')
    state['project']['revision']=99
    assert_equal 'Panel',r[:value]['catalog']['entries'][0]['label']
    assert_equal 7,r[:value]['state']['project']['revision']
    assert_equal 'Panel',r[:value]['material_report']['bindings'][0]['material']['label']
  end
  def test_hashes_are_canonical_and_bind_all_registry_content
    data=catalog
    data['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Unused surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    first=prepare(design_state,data)[:value]
    data['entries'].reverse!
    second=prepare(design_state,data.to_a.reverse.to_h)[:value]
    assert_equal first['content_sha256'],second['content_sha256']
    payload=first.reject { |k,_| k=='content_sha256' }
    canonical=lambda { |v| v.is_a?(Hash) ? v.keys.sort.to_h { |k| [k,canonical.call(v[k])] } : v.is_a?(Array) ? v.map { |x| canonical.call(x) } : v }
    assert_equal Digest::SHA256.hexdigest(JSON.generate(canonical.call(payload))),first['content_sha256']
    data['entries'][0]['label']='Changed'
    third=prepare(design_state,data)[:value]
    refute_equal first['content_sha256'],third['content_sha256']
    refute_equal first['material_report']['catalog_sha256'],third['material_report']['catalog_sha256']
    assert_equal first['snapshot']['state_sha256'],third['snapshot']['state_sha256']
  end
  def test_revision_and_width_changes_rebuild_geometry_and_bindings
    before=prepare[:value]
    state=design_state
    state['project']['revision']=8
    state['project']['articles'][0]['parameter_values']['W']=length(800)
    after=prepare(state)
    assert after[:ok],after[:diagnostics].inspect
    assert_equal 8,after[:value]['material_report']['source_revision']
    refute_equal before['content_sha256'],after[:value]['content_sha256']
    assert_equal '764',after[:value]['snapshot']['carcass_previews'][0]['panels'][2]['face_size'][0]['numeric']['numerator']
  end
  def test_derived_input_invalid_policy_and_resource_exhaustion_are_rejected
    error('E_SCHEMA_UNSUPPORTED',prepare({'schema'=>'jpimos.carcass-design-snapshot/1'}))
    error('E_INPUT_CONTRACT',JPImosPro::Design::MaterialPreparation.prepare(state:design_state,catalog:catalog,numeric_policy:{}))
    error('E_RESOURCE_LIMIT',prepare(design_state,catalog,{work:1}))
    data=catalog;data['entries'][0]['provenance']['kind']='manufacturer_verified'
    error('E_INPUT_CONTRACT',prepare(design_state,data))
  end
  def test_empty_project_and_registry_return_empty_derived_collections
    state=design_state
    state['project']['articles']=[]
    state['construction_requests']=[]
    r=prepare(state,{'schema'=>'jpimos.material-catalog/1','entries'=>[]})
    assert r[:ok],r[:diagnostics].inspect
    assert_empty r[:value]['snapshot']['carcass_previews']
    assert_empty r[:value]['material_report']['bindings']
  end
  def test_aggregate_work_cannot_be_reset_between_material_and_geometry_components
    limits={work:16_000}
    assert JPImosPro::Materials::Catalog.verify_references(state:design_state,catalog:catalog,limits:limits)[:ok]
    assert JPImosPro::Construction.build_carcass(document:valid_document,request:request,numeric_policy:policy,limits:limits)[:ok]
    r=prepare(design_state,catalog,limits)
    error('E_RESOURCE_LIMIT',r)
    assert_nil r[:value]
    assert_equal r[:diagnostics],prepare(design_state,catalog,limits)[:diagnostics]
    assert prepare[:ok]
  end
  def test_failed_construction_returns_no_resolved_material_package
    state=design_state
    state['construction_requests'][0]['panels']['left']['finished_substrate_thickness']=length(600)
    r=prepare(state)
    error('E_INFEASIBLE_CONSTRUCTION',r)
    assert_nil r[:value]
    assert_equal '/construction_requests/0/panels',r[:diagnostics][0][:json_pointer]
  end
end
