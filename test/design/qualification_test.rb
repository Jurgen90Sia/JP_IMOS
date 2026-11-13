require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/design'
require_relative 'fixtures'
class DesignQualificationTest < Minitest::Test
  include DesignFixtures
  D=JPImosPro::Design
  C=JPImosPro::ProjectCore
  def prepare(current,replacement,limits={},p=policy)
    D.prepare_revision(current:current,replacement:replacement,expected_revision:current['project']['revision'],numeric_policy:p,limits:limits)
  end
  def test_frozen_callers_shared_budget_and_independent_recovery
    current=D.validate(state:design_state)[:value]
    replacement=Marshal.load(Marshal.dump(current))
    replacement['construction_requests'][0]['panels']['left']['finished_substrate_thickness']=length(19)
    replacement=D.validate(state:replacement)[:value]
    r=prepare(current,replacement,{work:3000})
    error('E_RESOURCE_LIMIT',r)
    assert_equal r[:diagnostics],prepare(current,replacement,{work:3000})[:diagnostics]
    assert prepare(current,replacement)[:ok]
    assert current.frozen?
    assert replacement.frozen?
    assert_equal 7,replacement['project']['revision']
    error('E_INPUT_CONTRACT',prepare(current,replacement,{},nil))
    error('E_INPUT_CONTRACT',prepare(current,replacement,{},policy.merge(backend_id:"\xFF".b.force_encoding('UTF-8'))))
  end
  def test_data_only_inputs_unsupported_snapshots_and_duplicate_keys
    source=design_state
    source['project']['revision']=Object.new
    error('E_INPUT_CONTRACT',D.validate(state:source))
    error('E_INPUT_CONTRACT',D.validate(state:Object.new))
    error('E_DUPLICATE_JSON_KEY',D.decode(source:'{"project":{"revision":1,"revi\u0073ion":2}}'))
    source=design_state
    source['schema']='jpimos.carcass-design-snapshot/1'
    error('E_SCHEMA_UNSUPPORTED',D.validate(state:source))
    source=design_state
    source['construction_requests'][0]['skip_validation']=true
    error('E_INPUT_CONTRACT',D.validate(state:source))
  end
  def test_lexical_request_error_selection_keeps_output_array_order
    source=design_state
    base=source['project']['articles'][0]
    source['project']['articles']=Array.new(12) { |i| Marshal.load(Marshal.dump(base)).merge('id'=>uuid(100+i)) }
    source['construction_requests']=Array.new(12) { |i| request.merge('article_instance_id'=>uuid(100+i)) }
    [2,10].each { |i| source['construction_requests'][i]['panels']['left']['finished_substrate_thickness']=length(0) }
    r=D.validate(state:source)
    error('E_DOMAIN',r)
    assert_equal '/construction_requests/10/panels/left/finished_substrate_thickness',r[:diagnostics][0][:json_pointer]
  end
  def test_current_definition_budget_errors_stay_in_the_owned_project_path
    project=C::Document.validate(valid_document,C::CoreBudget.new({}))
    b=C::CoreBudget.new(work:1);b.tick
    e=assert_raises(C::Fault) { D.replacement_guard(project,project,b) }
    assert_equal 'E_RESOURCE_LIMIT',e.code
    assert_equal '/current/project/definitions',e.json_pointer
  end
  def test_snapshot_runtime_failures_select_lexical_request_pointer
    current=design_state
    base=current['project']['articles'][0]
    current['project']['articles']=Array.new(12) { |i| Marshal.load(Marshal.dump(base)).merge('id'=>uuid(100+i)) }
    current['construction_requests']=Array.new(12) { |i| request.merge('article_instance_id'=>uuid(100+i)) }
    replacement=Marshal.load(Marshal.dump(current))
    [2,10].each { |i| replacement['construction_requests'][i]['panels']['left']['finished_substrate_thickness']=length(600) }
    r=prepare(current,replacement)
    error('E_INFEASIBLE_CONSTRUCTION',r)
    assert_equal '/replacement/construction_requests/10/panels',r[:diagnostics][0][:json_pointer]
  end
  def test_preview_and_resolved_snapshots_cannot_be_imported_as_authoring_state
    preview=JPImosPro::Construction.build_carcass(document:valid_document,request:request,numeric_policy:policy)[:value]
    error('E_SCHEMA_UNSUPPORTED',D.decode(source:JSON.generate(preview)))
    error('E_SCHEMA_UNSUPPORTED',D.encode(state:preview))
    error('E_SCHEMA_UNSUPPORTED',D.validate(state:valid_document))
    current=design_state;replacement=Marshal.load(Marshal.dump(current));replacement['project']['locale']='en'
    snapshot=prepare(current,replacement)[:value]['snapshot']
    error('E_SCHEMA_UNSUPPORTED',D.validate(state:snapshot))
  end
end
