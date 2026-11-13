require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/design'
require_relative 'fixtures'
class DesignStateTest < Minitest::Test
  include DesignFixtures
  D=JPImosPro::Design
  def test_state_owns_project_and_requests_without_mutating_callers
    source=design_state
    source['project']['articles'][0]['parameter_values']['W']=length(1201,2)
    r=D.validate(state:source)
    assert r[:ok],r[:diagnostics].inspect
    assert r[:value]['project'].frozen?
    assert r[:value]['construction_requests'][0]['panels']['left'].frozen?
    refute source.frozen?
    refute source['construction_requests'].frozen?
    encoded=D.encode(state:source)
    assert encoded[:ok]
    decoded=D.decode(source:encoded[:value])
    assert decoded[:ok]
    assert_equal r[:value],decoded[:value]
    assert_includes encoded[:value],'Kuzhinë çeliku'
    assert_equal encoded[:value],D.encode(state:source.to_a.reverse.to_h)[:value]
  end
  def test_closed_schema_duplicate_json_and_exact_article_coverage
    source=design_state;source['construction_requests']=[]
    error('E_REFERENCE_MISSING',D.validate(state:source))
    source=design_state;source['construction_requests'] << source['construction_requests'][0]
    error('E_DUPLICATE_ID',D.validate(state:source))
    source=design_state;source['construction_requests'][0]['article_instance_id']=uuid(999)
    error('E_REFERENCE_MISSING',D.validate(state:source))
    source=design_state;source['schema']='jpimos.carcass-design/2'
    error('E_SCHEMA_UNSUPPORTED',D.validate(state:source))
    source=design_state;source['snapshot']={}
    error('E_INPUT_CONTRACT',D.validate(state:source))
    error('E_DUPLICATE_JSON_KEY',D.decode(source:'{"schema":"x","schema":"y"}'))
    source=design_state;source['project']['articles']=[];source['project']['definitions']=[];source['construction_requests']=[]
    assert D.validate(state:source)[:ok]
  end
  def test_project_and_request_errors_are_scoped
    source=design_state;source['project'].delete('locale')
    r=D.validate(state:source)
    error('E_INPUT_CONTRACT',r)
    assert_equal '/project/locale',r[:diagnostics][0][:json_pointer]
    source=design_state;source['construction_requests'][0]['panels']['left']['finished_substrate_thickness']=length(0)
    r=D.validate(state:source)
    error('E_DOMAIN',r)
    assert_equal '/construction_requests/0/panels/left/finished_substrate_thickness',r[:diagnostics][0][:json_pointer]
  end
end
