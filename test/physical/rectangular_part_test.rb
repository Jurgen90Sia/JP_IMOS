require 'minitest/autorun'
require 'json'
require 'digest'
require_relative '../../lib/jp_imos_pro/construction'
require_relative '../../lib/jp_imos_pro/physical/rectangular_part'
require_relative '../construction/fixtures'

class RectangularPhysicalPartTest < Minitest::Test
  include CarcassFixtures
  def intent
    {'schema'=>'jpimos.rectangular-part-intent/1','id'=>uuid(1000),
      'occurrence_ref'=>{'article_instance_id'=>uuid(4),'role'=>'left'},
      'owner_zone_ref'=>{'article_instance_id'=>uuid(4),'authored_zone_id'=>uuid(3)},
      'rule_version'=>'top_bottom_between_sides-v1','face_size'=>[length(600),length(400)],
      'frame'=>{'origin'=>[length(100),length(200),length(300)],'basis'=>[[1,0,0],[0,1,0],[0,0,1]]},
      'characteristic'=>characteristic,'grain'=>{'substrate'=>'u','surfaces'=>[]},
      'edges'=>%w[u_min u_max v_min v_max].to_h { |key| [key,{'kind'=>'none'}] }}
  end
  def build(data=intent,limits={})
    JPImosPro::Physical::RectangularPart.build(intent:data,limits:limits)
  end
  def layered
    data=intent
    data['characteristic']['dimensional_surfaces']=[surface('near',1),surface('far',2),surface('near',1,2)]
    data['grain']['surfaces']=%w[u v none]
    data
  end
  def n(dto)
    value=dto.fetch('numeric')
    Rational(value.fetch('numerator'),value.fetch('denominator'))
  end
  def test_bare_substrate_and_finished_solid_share_dimensions_not_nominal_purchase_thickness
    r=build
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal 'prepared_unbound_part',p['status']
    assert_equal [600,400,18],p['substrate_dimensions'].map { |d| n(d) }
    assert_equal [600,400,18],p['finished_dimensions'].map { |d| n(d) }
    assert_equal 19,n(p['characteristic']['nominal_purchase_thickness'])
    assert_equal 4_320_000,n(p['actual_volume'])
    assert_equal p['finished_geometry'],p['substrate_geometry']
    assert_empty p['surface_layers']
    assert_equal 'caller_declared_unverified_catalog',p['characteristic']['material_reference_status']
  end
  def test_interleaved_layers_form_disjoint_slabs_and_keep_source_indices
    r=build(layered)
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal Rational(43,2),n(p['finished_dimensions'][2])
    assert_equal [100,200,Rational(603,2)],p['substrate_geometry']['bbox_min'].map { |d| n(d) }
    assert_equal [700,600,Rational(639,2)],p['substrate_geometry']['bbox_max'].map { |d| n(d) }
    layers=p['surface_layers']
    assert_equal [0,1,2],layers.map { |l| l['source_index'] }
    assert_equal %w[near far near],layers.map { |l| l['side'] }
    assert_equal [300,Rational(639,2),301],layers.map { |l| n(l['geometry']['bbox_min'][2]) }
    assert_equal [240_000,480_000,120_000],layers.map { |l| n(l['geometry']['finished_envelope_volume']) }
    assert_equal 5_160_000,n(p['actual_volume'])
    assert_equal Rational(643,2),n(p['finished_geometry']['bbox_max'][2])
    assert_equal %w[u v none],layers.map { |l| l['grain'] }
  end
  def test_offsets_follow_reversed_part_normal_rather_than_global_z
    data=layered
    data['frame']['basis']=[[1,0,0],[0,-1,0],[0,0,-1]]
    r=build(data)
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal [100,-200,Rational(561,2)],p['substrate_geometry']['bbox_min'].map { |d| n(d) }
    assert_equal [700,200,Rational(597,2)],p['substrate_geometry']['bbox_max'].map { |d| n(d) }
    assert_equal Rational(557,2),n(p['finished_geometry']['bbox_min'][2])
    assert_equal 'u',p['grain']['substrate']
    assert_equal 5_160_000,n(p['actual_volume'])
  end
  def test_side_panel_offsets_follow_article_x_with_grain_in_local_u
    data=layered
    data['frame']['basis']=[[0,1,0],[0,0,1],[1,0,0]]
    r=build(data)
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal [Rational(203,2),200,300],p['substrate_geometry']['bbox_min'].map { |d| n(d) }
    assert_equal [Rational(239,2),800,700],p['substrate_geometry']['bbox_max'].map { |d| n(d) }
    assert_equal [100,200,300],p['finished_geometry']['bbox_min'].map { |d| n(d) }
    assert_equal Rational(243,2),n(p['finished_geometry']['bbox_max'][0])
    assert_equal 'u',p['grain']['substrate']
  end
  def test_missing_unknown_or_misaligned_grain_is_not_assumed_none
    data=intent;data.delete('grain')
    error('E_INPUT_CONTRACT',build(data))
    data=intent;data['grain']['substrate']='unknown'
    error('E_INPUT_CONTRACT',build(data))
    data=layered;data['grain']['surfaces'].pop
    error('E_INPUT_CONTRACT',build(data))
    data=intent;data['grain']['substrate']='none'
    assert build(data)[:ok]
  end
  def test_edges_are_complete_and_no_band_is_silently_discarded
    data=intent;data['edges'].delete('u_min')
    error('E_INPUT_CONTRACT',build(data))
    data=intent;data['edges']['u_min']={'kind'=>'band','thickness'=>length(1)}
    error('E_PART_PROFILE_UNSUPPORTED',build(data))
    data=intent;data['edges']['u_min']['material_ref']={'id'=>uuid(900),'version'=>1}
    error('E_INPUT_CONTRACT',build(data))
  end
  def test_identity_rule_and_frame_validation_reject_incompatible_inputs
    data=intent;data['owner_zone_ref']['article_instance_id']=uuid(5)
    error('E_REFERENCE_MISMATCH',build(data))
    data=intent;data['id']='not-a-uuid'
    error('E_INPUT_CONTRACT',build(data))
    data=intent;data['rule_version']='unknown'
    error('E_PART_PROFILE_UNSUPPORTED',build(data))
    data=intent;data['frame']['basis']=[[1,0,0],[0,1,0],[0,0,-1]]
    error('E_INVALID_GEOMETRY',build(data))
    data=intent;data['face_size'][0]=length(0)
    error('E_INVALID_GEOMETRY',build(data))
    data=intent;data['characteristic']['finished_substrate_thickness']=length(0)
    error('E_DOMAIN',build(data))
  end
  def test_owned_immutable_output_survives_caller_changes_and_hash_is_canonical
    data=layered
    original=Marshal.dump(data)
    r=build(data)
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal original,Marshal.dump(data)
    refute data.frozen?
    assert p.frozen?
    assert p['surface_layers'][0]['geometry']['solid_spec']['frame']['basis'][0].frozen?
    reordered=build(data.to_a.reverse.to_h)[:value]
    assert_equal p['content_sha256'],reordered['content_sha256']
    canon=lambda { |x| x.is_a?(Hash) ? x.keys.sort.to_h { |k| [k,canon.call(x[k])] } : x.is_a?(Array) ? x.map { |v| canon.call(v) } : x }
    body=p.reject { |k,_| k=='content_sha256' }
    assert_equal Digest::SHA256.hexdigest(JSON.generate(canon.call(body))),p['content_sha256']
    data['frame']['origin'][0]['numeric']['numerator'].replace('999')
    assert_equal 100,n(p['finished_geometry']['bbox_min'][0])
    data['grain']['substrate']='v'
    refute_equal p['content_sha256'],build(data)[:value]['content_sha256']
  end
  def test_derived_data_executable_values_and_resource_exhaustion_fail_atomically
    data=intent;data['schema']='jpimos.rectangular-physical-part/1'
    error('E_SCHEMA_UNSUPPORTED',build(data))
    data=intent;data['eval']='1+1'
    error('E_INPUT_CONTRACT',build(data))
    error('E_INPUT_CONTRACT',build(Object.new))
    error('E_RESOURCE_LIMIT',build(layered,{work:1}))
    data=intent;data['frame']['origin'][0]=length(1,1,false)
    error('E_INEXACT_DIVISION_INPUT',build(data))
    assert build[:ok]
  end
  def test_multiple_solids_spend_one_budget_and_recover_on_a_new_request
    limits={work:8_000}
    assert build(intent,limits)[:ok]
    r=build(layered,limits)
    error('E_RESOURCE_LIMIT',r)
    assert_nil r[:value]
    assert_equal r[:diagnostics],build(layered,limits)[:diagnostics]
    assert build(layered)[:ok]
  end
end
