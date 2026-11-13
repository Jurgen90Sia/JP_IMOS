require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative '../../lib/jp_imos_pro/materials/context'
require_relative '../../lib/jp_imos_pro/construction/request'
require_relative '../construction/fixtures'
class FinishedContextTest < Minitest::Test
  include CarcassFixtures
  C=JPImosPro::ProjectCore
  M=JPImosPro::Materials::Context
  def resolve_context(input)
    M.resolve(characteristic:input,budget:C::CoreBudget.new({}),pointer:'/characteristic')
  end
  def test_finished_stack_keeps_nominal_and_side_contributions_separate
    input=characteristic
    input['finished_substrate_thickness']=length(37,2)
    input['dimensional_surfaces']=[surface('near',1,2),surface('far',1,2)]
    context=resolve_context(input)
    assert_equal [Rational(39,2)],rationals([context['finished_stack_thickness']])
    assert_equal [19],rationals([context['nominal_purchase_thickness']])
    assert_equal [Rational(1,2),Rational(1,2)],rationals([context['near_surface_thickness'],context['far_surface_thickness']])
    assert_equal 'caller_declared_unverified_catalog',context['material_reference_status']
    assert context['dimensional_surfaces'][0].frozen?
    refute input.frozen?
    refute input['material_ref'].frozen?
    input['dimensional_surfaces']=[]
    assert_equal [Rational(37,2)],rationals([resolve_context(input)['finished_stack_thickness']])
  end
  def test_invalid_or_ambiguous_characteristics_fail_without_fallback
    [{field:'finished_substrate_thickness',value:length(0),code:'E_DOMAIN'},
     {field:'finished_substrate_thickness',value:length(-1),code:'E_DOMAIN'},
     {field:'finished_substrate_thickness',value:length(18,1,false),code:'E_INEXACT_DIVISION_INPUT'},
     {field:'finished_substrate_thickness',value:scalar(18),code:'E_UNIT_MISMATCH'},
     {field:'nominal_purchase_thickness',value:18.0,code:'E_INPUT_CONTRACT'},
     {field:'policy',value:'guess_total',code:'E_CONSTRUCTION_UNSUPPORTED'}].each do |entry|
      input=characteristic;input[entry[:field]]=entry[:value]
      e=assert_raises(C::Fault) { resolve_context(input) }
      assert_equal entry[:code],e.code
    end
    input=characteristic;input['finished_stack_thickness']=length(18)
    assert_equal 'E_INPUT_CONTRACT',assert_raises(C::Fault) { resolve_context(input) }.code
    input=characteristic;input['dimensional_surfaces']=Array.new(17) { surface('near',1) }
    assert_equal 'E_RESOURCE_LIMIT',assert_raises(C::Fault) { resolve_context(input) }.code
    input=characteristic;input['material_ref']['version']=0
    assert_equal 'E_INPUT_CONTRACT',assert_raises(C::Fault) { resolve_context(input) }.code
  end
  def test_construction_request_is_closed_pinned_and_canonical
    input=request
    r=JPImosPro::Construction::Request.validate(input,C::CoreBudget.new({}))
    assert r.frozen?
    assert_equal %w[left right top bottom],r['panels'].keys
    refute input.frozen?
    [['principle','guess','E_CONSTRUCTION_UNSUPPORTED'],['schema','other','E_SCHEMA_UNSUPPORTED'],
     ['article_instance_id','not-an-id','E_INPUT_CONTRACT']].each do |key,value,code|
      input=request;input[key]=value
      e=assert_raises(C::Fault) { JPImosPro::Construction::Request.validate(input,C::CoreBudget.new({})) }
      assert_equal code,e.code
    end
    input=request;input['panels'].delete('right')
    assert_equal 'E_INPUT_CONTRACT',assert_raises(C::Fault) { JPImosPro::Construction::Request.validate(input,C::CoreBudget.new({})) }.code
  end
  def test_numeric_stack_overflow_has_the_characteristic_pointer
    input=characteristic
    input['finished_substrate_thickness']=length((1<<4096)-1)
    input['dimensional_surfaces']=[surface('near',1)]
    e=assert_raises(C::Fault) { resolve_context(input) }
    assert_equal 'E_RESOURCE_LIMIT',e.code
    assert_equal '/characteristic',e.json_pointer
  end
end
