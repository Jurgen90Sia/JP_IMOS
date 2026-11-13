require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'

class CoreParametersTest < Minitest::Test
  include CoreFixtures
  C = JPImosPro::ProjectCore
  def encode(doc)
    C.encode_document(document:doc)
  end
  def error(code,doc)
    result=encode(doc)
    refute result[:ok],result.inspect
    assert_equal code,result[:diagnostics][0][:code]
    assert_nil result[:value]
  end
  def optional(name='a',type='Scalar',default=scalar(0))
    {'name'=>name,'expected_type'=>type,'default_value'=>default,'required'=>false}
  end
  def test_required_dimensions_and_override_presence
    %w[W H D].each do |name|
      doc=valid_document
      doc['articles'][0]['parameter_values'].delete(name)
      error('E_PARAMETER_REQUIRED',doc)
      [length(0),length(-1),length(600,1,false),scalar(1)].each do |bad|
        doc=valid_document
        doc['articles'][0]['parameter_values'][name]=bad
        error(bad['type']=='Scalar' ? 'E_UNIT_MISMATCH' : (bad['numeric']['exact'] ? 'E_DOMAIN' : 'E_INEXACT_DIVISION_INPUT'),doc)
      end
    end
    doc=valid_document
    doc['articles'][0]['parameter_values']['extra']=scalar(1)
    error('E_PARAMETER_UNKNOWN',doc)
    doc=valid_document
    doc['definitions'][0]['parameters'].pop
    error('E_PARAMETER_REQUIRED',doc)
  end
  def test_defaults_do_not_inject_authored_overrides_or_confuse_false_and_zero
    doc=valid_document
    doc['definitions'][0]['parameters'] << optional << optional('flag','Boolean',boolean(false))
    result=encode(doc)
    assert result[:ok],result.inspect
    refute JSON.parse(result[:value])['articles'][0]['parameter_values'].key?('a')
    doc['articles'][0]['parameter_values']['a']=scalar(0)
    doc['articles'][0]['parameter_values']['flag']=boolean(false)
    assert encode(doc)[:ok]
    assert_equal false,doc['articles'][0]['parameter_values']['flag']['value']
    doc['definitions'][0]['parameters'][-2]['default_value']=nil
    doc['articles'][0]['parameter_values'].delete('a')
    error('E_PARAMETER_REQUIRED',doc)
  end
  def test_declarations_reject_conflicts_and_unsupported_types
    %w[pi X Y sin max if ZONE_U ZONE_V ZONE_W].each do |name|
      doc=valid_document
      doc['definitions'][0]['parameters'] << optional(name)
      error('E_RESERVED_SYMBOL',doc)
    end
    doc=valid_document
    doc['definitions'][0]['parameters'] << optional('W')
    error('E_DUPLICATE_ID',doc)
    doc=valid_document
    doc['definitions'][0]['parameters'] << optional('angle','Angle',nil)
    error('E_TYPE_UNSUPPORTED',doc)
    doc=valid_document
    doc['definitions'][0]['parameters'] << optional('a','Scalar',length(1))
    error('E_UNIT_MISMATCH',doc)
    doc=valid_document
    doc['definitions'][0]['parameters'][0]['default_value']=length(600)
    error('E_INPUT_CONTRACT',doc)
    doc=valid_document
    doc['definitions'][0]['parameters'] << optional('a'.encode('UTF-16LE'))
    error('E_INPUT_CONTRACT',doc)
  end
end
