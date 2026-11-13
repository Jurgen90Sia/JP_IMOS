require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative '../../lib/jp_imos_pro/materials/context'
require_relative '../../lib/jp_imos_pro/construction/request'
require_relative '../../lib/jp_imos_pro/construction/carcass_rule'
require_relative '../../lib/jp_imos_pro/geometry/rectangular_panel'
require_relative '../construction/fixtures'
class RectangularPanelTest < Minitest::Test
  include CarcassFixtures
  C=JPImosPro::ProjectCore
  G=JPImosPro::Geometry::RectangularPanel
  def recipe
    {'occurrence_ref'=>{'article_instance_id'=>uuid(4),'role'=>'bottom'},'owner_zone_ref'=>{},'rule_version'=>'top_bottom_between_sides-v1',
      'role'=>'bottom','kind'=>'rectangular_panel','characteristic'=>{},'face_size'=>[length(600),length(300)],'finished_thickness'=>length(18),
      'frame'=>{'origin'=>[length(0),length(0),length(0)],'basis'=>[[1,0,0],[0,1,0],[0,0,1]]}}
  end
  def test_rectangular_solid_has_exact_bounds_volume_and_outward_closed_faces
    input=recipe
    geometry=G.from_recipe(recipe:input,budget:C::CoreBudget.new({}))
    assert_equal [0,0,0],rationals(geometry['bbox_min'])
    assert_equal [600,300,18],rationals(geometry['bbox_max'])
    n=geometry['finished_envelope_volume']['numeric']
    assert_equal Rational(3240000),Rational(n['numerator'],n['denominator'])
    assert_equal 'mm3',geometry['finished_envelope_volume']['unit']
    assert_equal 8,geometry['article_vertices'].size
    assert_equal 6,geometry['face_loops'].size
    assert_equal [],geometry['solid_spec']['holes']
    vertices=geometry['article_vertices'].map { |v| rationals(v) }
    edges=Hash.new(0)
    geometry['face_loops'].each_value do |face|
      p0,p1,p2=face.first(3).map { |i| vertices[i] }
      a=p1.zip(p0).map { |x,y| x-y };b=p2.zip(p0).map { |x,y| x-y }
      cross=[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
      delta=p0.zip([300,150,9]).map { |x,y| x-y }
      assert_operator cross.zip(delta).sum { |x,y| x*y },:>,0
      face.each_with_index { |id,i| edges[[id,face[(i+1)%4]].sort]+=1 }
    end
    assert_equal 12,edges.size
    assert edges.values.all? { |count| count==2 }
    assert geometry['article_vertices'][0].frozen?
    refute input['frame'].frozen?
  end
  def test_converter_rejects_unsupported_holes_and_invalid_geometry
    input=recipe;input['holes']=[[]]
    assert_equal 'E_INVALID_GEOMETRY',assert_raises(C::Fault) { G.from_recipe(recipe:input,budget:C::CoreBudget.new({})) }.code
    input=recipe;input['kind']='general_contour'
    assert_equal 'E_CONSTRUCTION_UNSUPPORTED',assert_raises(C::Fault) { G.from_recipe(recipe:input,budget:C::CoreBudget.new({})) }.code
    input=recipe;input['frame']['basis']=[[1,0,0],[0,1,0],[0,0,-1]]
    assert_equal 'E_INVALID_GEOMETRY',assert_raises(C::Fault) { G.from_recipe(recipe:input,budget:C::CoreBudget.new({})) }.code
  end
  def test_volume_overflow_is_rejected_before_an_output_is_returned
    input=recipe;input['face_size']=[length(1<<2048),length(1<<2048)];input['finished_thickness']=length(1)
    e=assert_raises(C::Fault) { G.from_recipe(recipe:input,budget:C::CoreBudget.new({})) }
    assert_equal 'E_RESOURCE_LIMIT',e.code
    refute input.frozen?
  end
end
