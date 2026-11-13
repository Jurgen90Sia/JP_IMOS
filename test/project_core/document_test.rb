require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'

class CoreDocumentTest < Minitest::Test
  include CoreFixtures
  C = JPImosPro::ProjectCore
  def encode(doc, limits = {})
    C.encode_document(document: doc, limits: limits)
  end
  def error(code, result, pointer = nil)
    refute result[:ok], result.inspect
    assert_nil result[:value]
    assert_equal code,result[:diagnostics].first[:code]
    assert_equal pointer,result[:diagnostics].first[:json_pointer] if pointer
  end
  def test_lossless_canonical_roundtrip_without_mutating_input
    doc = valid_document
    doc['articles'][0]['parameter_values']['W'] = length(3,10)
    result = encode(doc)
    assert result[:ok],result.inspect
    decoded = C.decode_document(source:result[:value])
    assert decoded[:ok],decoded.inspect
    assert_equal doc,decoded[:value]
    assert decoded[:value]['articles'][0]['parameter_values'].frozen?
    assert decoded[:value]['definitions'][0]['label'].frozen?
    refute doc.frozen?
    refute doc['articles'].frozen?
    assert_includes result[:value],'Kuzhinë çeliku'
    reordered = doc.to_a.reverse.to_h
    reordered['articles'][0]['parameter_values'] = reordered['articles'][0]['parameter_values'].to_a.reverse.to_h
    assert_equal result[:value],encode(reordered)[:value]
    assert_equal 'UTF-8',result[:value].encoding.name
  end
  def test_closed_schema_and_field_types
    doc = valid_document
    doc['schema'] = 'jpimos.project/1'
    error('E_SCHEMA_UNSUPPORTED',encode(doc),'/schema')
    doc = valid_document
    doc['unknown'] = 0
    error('E_INPUT_CONTRACT',encode(doc),'/unknown')
    doc = valid_document
    doc['revision'] = 9_007_199_254_740_992
    error('E_INPUT_CONTRACT',encode(doc),'/revision')
    doc = valid_document
    doc['definitions'][0]['source_refs'] = [{'requirement_id'=>'r','classification'=>'VERIFIED','pdf'=>nil,'page'=>nil,'conflict_id'=>nil}]
    error('E_INPUT_CONTRACT',encode(doc),'/definitions/0/source_refs/0/pdf')
    doc = valid_document
    doc['definitions'][0]['label'] = 'a'*257
    error('E_RESOURCE_LIMIT',encode(doc),'/definitions/0/label')
    doc = valid_document
    doc['project_id'] = 'ABC'
    error('E_INPUT_CONTRACT',encode(doc),'/project_id')
    doc = valid_document
    doc.delete('locale')
    error('E_INPUT_CONTRACT',encode(doc),'/locale')
  end
  def test_malformed_quantities_and_host_objects_are_contract_errors
    [1.5,Float::NAN,{},length(2,2),length(1,0),length(1).merge(:unit=>'mm')].each do |bad|
      doc = valid_document
      doc['articles'][0]['parameter_values']['W'] = bad
      error('E_INPUT_CONTRACT',encode(doc))
    end
    doc = valid_document
    doc['articles'][0]['origin'][0]['numeric']['numerator'] = '1'.encode('UTF-16LE')
    error('E_INPUT_CONTRACT',encode(doc))
    doc = valid_document
    doc['loop'] = doc
    error('E_INPUT_CONTRACT',encode(doc))
    doc = valid_document
    shared = length(0)
    doc['articles'][0]['origin'] = [shared,shared,shared]
    assert encode(doc)[:ok]
    refute shared.frozen?
    error('E_INPUT_CONTRACT',encode(Object.new))
  end
  def test_public_decode_does_not_return_partial_or_executable_data
    error('E_DUPLICATE_JSON_KEY',C.decode_document(source:'{"revision":1,"revision":2}'),'/revision')
    error('E_INPUT_CONTRACT',C.decode_document(source:'[]'))
    error('E_INPUT_CONTRACT',C.decode_document(source:'{"json_class":"Object"}'))
    doc = valid_document
    doc['articles'][0]['origin'] = [length(0)]
    error('E_INPUT_CONTRACT',encode(doc),'/articles/0/origin')
  end
  def test_host_callbacks_and_aggregate_bytes_are_rejected_before_serialization
    bomb=Class.new do
      def ==(_other)
        raise 'host comparison callback must not run'
      end
      def to_json(*_args)
        raise 'host serializer callback must not run'
      end
    end.new
    doc=valid_document
    doc['revision']=bomb
    error('E_INPUT_CONTRACT',encode(doc))
    doc=valid_document
    doc['definitions'][0]['label']='a'*300
    doc['definitions'][0]['source_refs']=[{'requirement_id'=>'b'*300,'classification'=>'PROPOSED','pdf'=>nil,'page'=>nil,'conflict_id'=>nil}]
    error('E_RESOURCE_LIMIT',encode(doc,{json_bytes:500}))
  end
  def test_first_field_error_uses_lexical_json_pointer_even_for_array_indexes
    doc=valid_document
    doc['articles']=Array.new(12) { |i| Marshal.load(Marshal.dump(doc['articles'][0])).merge('id'=>uuid(100+i)) }
    doc['articles'][2]['origin']='bad'
    doc['articles'][10]['origin']='bad'
    error('E_INPUT_CONTRACT',encode(doc),'/articles/10/origin')
    doc=valid_document
    doc['zzz']=1
    doc['articles']='bad'
    error('E_INPUT_CONTRACT',encode(doc),'/articles')
    doc=valid_document
    doc['/']=0
    doc['a']=0
    error('E_INPUT_CONTRACT',encode(doc),'/a')
  end
end
