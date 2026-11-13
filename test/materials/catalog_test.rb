require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/materials/catalog'
require_relative '../design/fixtures'
class MaterialCatalogTest < Minitest::Test
  include DesignFixtures
  M=JPImosPro::Materials::Catalog
  def catalog
    {'schema'=>'jpimos.material-catalog/1','entries'=>[{'id'=>uuid(900),'version'=>1,'label'=>'Panel i deklaruar','category'=>'panel','provenance'=>{'kind'=>'user_declared','note'=>'Synthetic test material'}}]}
  end
  def verify(state=design_state,data=catalog)
    M.verify_references(state:state,catalog:data)
  end
  def test_pinned_references_resolve_without_manufacturer_claims_or_mutation
    state=design_state;data=catalog
    r=verify(state,data)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 4,r[:value]['bindings'].size
    assert_equal 'registry_resolved_user_declared',r[:value]['status']
    assert r[:value]['bindings'][0].frozen?
    refute data.frozen?
    refute state.frozen?
  end
  def test_missing_duplicate_and_wrong_category_refs_fail
    data=catalog;data['entries'][0]['version']=2
    error('E_MATERIAL_REFERENCE_UNRESOLVED',verify(design_state,data))
    data=catalog;data['entries'] << data['entries'][0]
    error('E_DUPLICATE_ID',verify(design_state,data))
    data=catalog;data['entries'][0]['category']='surface'
    error('E_MATERIAL_CATEGORY_MISMATCH',verify(design_state,data))
    data=catalog;data['entries'][0]['provenance']['kind']='manufacturer_verified'
    error('E_INPUT_CONTRACT',verify(design_state,data))
  end
  def test_surface_refs_are_separate_and_closed_schema_is_enforced
    state=design_state
    state['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('near',1)]
    error('E_MATERIAL_REFERENCE_UNRESOLVED',verify(state))
    data=catalog
    data['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    assert verify(state,data)[:ok]
    data['entries'][0]['nominal_thickness']=19
    error('E_INPUT_CONTRACT',verify(state,data))
    error('E_INPUT_CONTRACT',M.verify_references(state:design_state,catalog:Object.new))
    error('E_RESOURCE_LIMIT',M.verify_references(state:design_state,catalog:catalog,limits:{work:1}))
  end
  def test_registry_hash_tracks_content_but_not_entry_or_property_order
    data=catalog
    data['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Unused surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    first=verify(design_state,data)
    data['entries'].reverse!
    second=verify(design_state,data.to_a.reverse.to_h)
    assert_equal first[:value]['catalog_sha256'],second[:value]['catalog_sha256']
    data['entries'][0]['label']='Changed'
    third=verify(design_state,data)
    refute_equal first[:value]['catalog_sha256'],third[:value]['catalog_sha256']
    assert_equal first[:value]['state_sha256'],third[:value]['state_sha256']
    refute data['entries'][0].frozen?
    assert_equal 'Panel i deklaruar',first[:value]['bindings'][0]['material']['label']
  end
end
