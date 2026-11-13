require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative '../../lib/jp_imos_pro/project_core/revision'
require_relative '../zones/fixtures'

class PreparedRevisionTest < Minitest::Test
  include ZoneFixtures
  C=JPImosPro::ProjectCore
  def budget(limits={})
    C::CoreBudget.new(limits)
  end
  def fault(code,pointer=nil)
    e=assert_raises(C::Fault) { yield }
    assert_equal code,e.code
    assert_equal pointer,e.json_pointer if pointer
    e
  end
  def test_current_revision_guards_before_any_replacement_resolution
    current=valid_document
    fault('E_REVISION_CONFLICT','/expected_revision') { C::Revision.current(current,6,budget) }
    [7.0,true,nil,'7',-1,9_007_199_254_740_992].each do |bad|
      fault('E_INPUT_CONTRACT','/expected_revision') { C::Revision.current(current,bad,budget) }
    end
    current['revision']=9_007_199_254_740_991
    fault('E_REVISION_EXHAUSTED','/current/revision') { C::Revision.current(current,current['revision'],budget) }
    assert_equal 9_007_199_254_740_991,current['revision']
    refute current.frozen?
  end
  def test_replacement_identity_revision_and_semantic_noop
    current=C::Revision.current(valid_document,7,budget)
    replacement=valid_document
    replacement['project_id']=uuid(999)
    fault('E_REVISION_CONFLICT','/replacement/project_id') { C::Revision.replacement(current,replacement,budget) }
    replacement=valid_document
    replacement['revision']=8
    fault('E_REVISION_CONFLICT','/replacement/revision') { C::Revision.replacement(current,replacement,budget) }
    fault('E_NO_CHANGE','/replacement') { C::Revision.replacement(current,valid_document,budget) }
    reordered=valid_document.to_a.reverse.to_h
    reordered['articles'][0]['parameter_values']=reordered['articles'][0]['parameter_values'].to_a.reverse.to_h
    fault('E_NO_CHANGE','/replacement') { C::Revision.replacement(current,reordered,budget) }
    replacement=valid_document
    replacement['articles'][0]['parameter_values']['W']=length(800)
    validated=C::Revision.replacement(current,replacement,budget)
    assert validated.frozen?
    refute replacement.frozen?
    assert_equal 7,validated['revision']
  end
  def test_definition_versions_are_immutable_within_a_revision_pair
    current=C::Revision.current(valid_document,7,budget)
    replacement=valid_document
    replacement['definitions'][0]['label']='Ndryshim'
    fault('E_DEFINITION_DUPLICATE','/replacement/definitions/0') { C::Revision.replacement(current,replacement,budget) }
    replacement['definitions'][0]['version']=2
    replacement['articles'][0]['definition_ref']['version']=2
    assert C::Revision.replacement(current,replacement,budget).frozen?
  end
  def prepare(current,replacement,expected=7,limits={},numeric_policy=policy)
    C.prepare_revision(current:current,replacement:replacement,expected_revision:expected,numeric_policy:numeric_policy,limits:limits)
  end
  def test_prepared_revision_contains_one_matching_immutable_document_and_snapshot
    current=partition(valid_document,'1:1')
    replacement=Marshal.load(Marshal.dump(current))
    replacement['articles'][0]['parameter_values']['W']=length(800)
    r=prepare(current,replacement)
    assert r[:ok],r[:diagnostics].inspect
    prepared=r[:value]
    assert_equal 7,prepared['base_revision']
    assert_equal 8,prepared['next_revision']
    assert_equal 8,prepared['document']['revision']
    assert_equal 8,prepared['zone_snapshot']['source_revision']
    assert_equal prepared['project_id'],prepared['zone_snapshot']['project_id']
    assert_equal [400,560,720],rationals(prepared['zone_snapshot']['zones'][1]['local_extents'])
    assert prepared.frozen?
    assert prepared['document']['articles'][0]['parameter_values'].frozen?
    assert prepared['zone_snapshot']['zones'].frozen?
    assert_equal 7,current['revision']
    assert_equal 7,replacement['revision']
    assert_equal '600',current['articles'][0]['parameter_values']['W']['numeric']['numerator']
    refute current.frozen?
    refute replacement.frozen?
    assert_equal r,prepare(current,replacement)
  end
  def test_metadata_and_translation_edits_prepare_real_snapshots
    current=valid_document
    replacement=valid_document
    replacement['locale']='en'
    replacement['articles'][0]['origin']=[length(10),length(20),length(30)]
    r=prepare(current,replacement)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 8,r[:value]['next_revision']
    assert_equal 'en',r[:value]['document']['locale']
    assert_equal [10,20,30],rationals(r[:value]['zone_snapshot']['articles'][0]['origin'])
    replacement=valid_document
    replacement['definitions'][0]['label']='Version i ri'
    replacement['definitions'][0]['version']=2
    replacement['articles'][0]['definition_ref']['version']=2
    r=prepare(current,replacement)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 2,r[:value]['zone_snapshot']['zones'][0]['source_definition_ref']['version']
  end
  def test_failure_is_atomic_and_stale_revision_precedes_bad_replacement
    current=partition(valid_document,'1/$a:1')
    current['definitions'][0]['parameters'] << {'name'=>'a','expected_type'=>'Scalar','default_value'=>scalar(1),'required'=>false}
    replacement=Marshal.load(Marshal.dump(current))
    replacement['articles'][0]['parameter_values']['a']=scalar(0)
    error('E_REVISION_CONFLICT',prepare(current,replacement,6))
    r=prepare(current,replacement)
    error('E_DIV_ZERO',r)
    d=r[:diagnostics][0]
    assert_equal '/replacement/definitions/0/zones/0/layout/expression/source',d[:json_pointer]
    assert_equal({start:0,end:4},d[:source_span])
    assert_equal 'jp-division-v1',d[:grammar_version]
    assert_equal 7,current['revision']
    assert_equal 7,replacement['revision']
    replacement['articles'][0]['parameter_values']['a']=scalar(1)
    replacement['locale']='en'
    assert prepare(current,replacement)[:ok]
    replacement=valid_document
    replacement['unknown']=1
    r=prepare(valid_document,replacement)
    error('E_INPUT_CONTRACT',r)
    assert_equal '/replacement/unknown',r[:diagnostics][0][:json_pointer]
  end
end
