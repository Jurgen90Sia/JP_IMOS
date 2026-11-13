require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative '../../lib/jp_imos_pro/materials/context'
require_relative '../../lib/jp_imos_pro/construction/request'
require_relative '../../lib/jp_imos_pro/construction/carcass_rule'
require_relative 'fixtures'
class CarcassRuleTest < Minitest::Test
  include CarcassFixtures
  C=JPImosPro::ProjectCore
  def build_rule(doc=valid_document,req=request)
    b=C::CoreBudget.new({})
    article=C.resolve_zones(document:doc,numeric_policy:policy)[:value]['articles'][0]
    contexts=req['panels'].each_with_object({}) { |(role,characteristic),h| h[role]=JPImosPro::Materials::Context.resolve(characteristic:characteristic,budget:b,pointer:'/request/panels/'+role) }
    JPImosPro::Construction::CarcassRule.build(article:article,contexts:contexts,budget:b)
  end
  def test_four_recipes_have_literal_finished_dimensions_origins_and_bases
    result=build_rule
    assert_equal [564,560,684],rationals(result['reference_opening']['extents'])
    assert_equal [18,0,18],rationals(result['reference_opening']['origin'])
    r=result['recipes']
    assert_equal %w[left right top bottom],r.map { |p| p['role'] }
    assert_equal [[560,720],[560,720],[564,560],[564,560]],r.map { |p| rationals(p['face_size']) }
    assert_equal [[0,0,0],[600,560,0],[18,560,720],[18,0,0]],r.map { |p| rationals(p['frame']['origin']) }
    assert_equal [[0,-1,0],[0,0,1],[-1,0,0]],r[1]['frame']['basis']
    assert_equal [[1,0,0],[0,-1,0],[0,0,-1]],r[2]['frame']['basis']
    assert r.frozen?
    refute r[0].key?('geometry')
  end
  def test_asymmetric_finished_stacks_and_view_orientation
    req=request
    req['panels']['right']=characteristic(20,21)
    req['panels']['top']=characteristic(16,19)
    req['panels']['bottom']=characteristic(22,25)
    doc=valid_document;doc['definitions'][0]['zones'][0]['orientation']='front'
    r=build_rule(doc,req)
    assert_equal [562,560,682],rationals(r['reference_opening']['extents'])
    assert_equal [18,560,720],rationals(r['recipes'][2]['frame']['origin'])
    assert_equal [16],rationals([r['recipes'][2]['finished_thickness']])
    assert_equal [560,720],rationals(r['recipes'][0]['face_size'])
  end
  def test_invalid_opening_fails_before_partial_recipes
    doc=valid_document;doc['articles'][0]['parameter_values']['W']=length(36)
    e=assert_raises(C::Fault) { build_rule(doc) }
    assert_equal 'E_INFEASIBLE_CONSTRUCTION',e.code
    doc=valid_document;doc['articles'][0]['parameter_values']['H']=length(35)
    assert_equal 'E_INFEASIBLE_CONSTRUCTION',assert_raises(C::Fault) { build_rule(doc) }.code
  end
end
