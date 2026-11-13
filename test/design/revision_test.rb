require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/design'
require_relative 'fixtures'
class DesignRevisionTest < Minitest::Test
  include DesignFixtures
  D=JPImosPro::Design
  def prepare(current,replacement,expected=7,limits={})
    D.prepare_revision(current:current,replacement:replacement,expected_revision:expected,numeric_policy:policy,limits:limits)
  end
  def test_request_only_edit_increments_the_single_project_revision
    current=design_state
    replacement=Marshal.load(Marshal.dump(current))
    replacement['construction_requests'][0]['panels']['left']['finished_substrate_thickness']=length(19)
    r=prepare(current,replacement)
    assert r[:ok],r[:diagnostics].inspect
    value=r[:value]
    assert_equal 7,value['base_revision']
    assert_equal 8,value['next_revision']
    assert_equal 8,value['state']['project']['revision']
    assert_equal 8,value['snapshot']['source_revision']
    assert_equal 8,value['snapshot']['zone_snapshot']['source_revision']
    preview=value['snapshot']['carcass_previews'][0]
    assert_equal 8,preview['source_context']['project_revision']
    assert_equal [563,560,684],rationals(preview['reference_opening']['extents'])
    assert_equal [19,560,720],rationals(preview['panels'][0]['geometry']['bbox_max'])
    assert_equal 64,value['snapshot']['state_sha256'].length
    assert value['state'].frozen?
    assert preview.frozen?
    refute current.frozen?
    refute replacement.frozen?
    assert_equal 7,current['project']['revision']
    assert_equal r,prepare(current,replacement)
  end
  def test_project_and_request_edits_are_one_change_with_atomic_failures
    current=design_state
    replacement=Marshal.load(Marshal.dump(current))
    replacement['project']['articles'][0]['parameter_values']['W']=length(800)
    replacement['construction_requests'][0]['panels']['left']['finished_substrate_thickness']=length(20)
    r=prepare(current,replacement);assert r[:ok]
    assert_equal 8,r[:value]['next_revision']
    assert_equal [762,560,684],rationals(r[:value]['snapshot']['carcass_previews'][0]['reference_opening']['extents'])
    error('E_REVISION_CONFLICT',prepare(current,replacement,6))
    replacement['project']['articles'][0]['parameter_values']['W']=length(38)
    r=prepare(current,replacement)
    error('E_INFEASIBLE_CONSTRUCTION',r)
    assert r[:diagnostics][0][:json_pointer].start_with?('/replacement/construction_requests/0')
    assert_equal 7,replacement['project']['revision']
    error('E_NO_CHANGE',prepare(current,Marshal.load(Marshal.dump(current)).to_a.reverse.to_h))
  end
  def test_two_articles_bind_eight_distinct_panels_and_request_order
    current=design_state
    current['project']['articles'] << Marshal.load(Marshal.dump(current['project']['articles'][0])).merge('id'=>uuid(50))
    current['construction_requests'] << request.merge('article_instance_id'=>uuid(50))
    replacement=Marshal.load(Marshal.dump(current))
    replacement['construction_requests'].reverse!
    r=prepare(current,replacement);assert r[:ok],r[:diagnostics].inspect
    previews=r[:value]['snapshot']['carcass_previews']
    assert_equal [uuid(50),uuid(4)],previews.map { |p| p['source_context']['article_instance_id'] }
    assert_equal 8,previews.sum { |p| p['panels'].size }
    assert_equal 8,previews.flat_map { |p| p['panels'].map { |x| x['occurrence_ref'] } }.uniq.size
    replacement['construction_requests'][1]['panels']['left']['finished_substrate_thickness']=length(0)
    r=prepare(current,replacement)
    error('E_DOMAIN',r)
    assert_equal '/replacement/construction_requests/1/panels/left/finished_substrate_thickness',r[:diagnostics][0][:json_pointer]
  end
  def test_existing_revision_guards_and_definition_immutability_survive
    current=design_state
    replacement=Marshal.load(Marshal.dump(current))
    replacement['project']['locale']='en'
    replacement['project']['definitions'][0]['label']='Changed same version'
    error('E_DEFINITION_DUPLICATE',prepare(current,replacement))
    current['project']['revision']=9_007_199_254_740_991
    error('E_REVISION_EXHAUSTED',prepare(current,current,current['project']['revision']))
    current=design_state
    replacement=Marshal.load(Marshal.dump(current));replacement['project']['locale']='en'
    error('E_INPUT_CONTRACT',prepare(current,replacement,true))
  end
end
