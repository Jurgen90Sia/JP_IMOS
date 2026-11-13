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
end
