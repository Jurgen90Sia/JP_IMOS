require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'

class CoreReferencesTest < Minitest::Test
  include CoreFixtures
  C=JPImosPro::ProjectCore
  def result(doc, limits={})
    C.encode_document(document:doc,limits:limits)
  end
  def error(code,doc,limits={})
    r=result(doc,limits)
    refute r[:ok]
    assert_nil r[:value]
    assert_equal code,r[:diagnostics][0][:code]
  end
  def partition(zone,children)
    zone['layout']={'kind'=>'partition','axis'=>'u','expression'=>{'grammar_version'=>'jp-division-v1','source'=>'1'},
      'slots'=>children.each_with_index.map { |_n,i| {'id'=>uuid(zone['id'][-12..-1].to_i*1000+i),'role'=>'zone'} }}
    zone['children']=children.each_with_index.map { |n,i| {'zone_id'=>uuid(n),'slot_id'=>zone['layout']['slots'][i]['id']} }
    zone
  end
  def chain(count)
    doc=valid_document
    zones=(3...(count+3)).map { |n| leaf(n) }
    zones.each_with_index { |z,i| partition(z,[i+4]) if i < zones.size-1 }
    doc['definitions'][0]['zones']=zones
    doc
  end
  def star(count, instances=1)
    doc=valid_document
    zones=(3...(count+3)).map { |n| leaf(n) }
    partition(zones[0],(4...(count+3)).to_a) if count>1
    doc['definitions'][0]['zones']=zones
    base=doc['articles'][0]
    doc['articles']=Array.new(instances) { |i| base.merge('id'=>uuid(20_000+i)) }
    doc
  end
  def test_pinned_definitions_and_occurrence_identity
    doc=valid_document
    doc['articles'] << doc['articles'][0].merge('id'=>uuid(5))
    assert result(doc)[:ok]
    doc['articles'][1]['definition_ref']={'id'=>uuid(2),'version'=>2}
    error('E_REFERENCE_MISSING',doc)
    doc['definitions'] << Marshal.load(Marshal.dump(doc['definitions'][0])).merge('version'=>2)
    assert result(doc)[:ok]
    doc['definitions'] << doc['definitions'][0]
    error('E_DEFINITION_DUPLICATE',doc)
    doc=valid_document
    doc['articles'] << doc['articles'][0]
    error('E_DUPLICATE_ID',doc)
  end
  def test_root_and_child_integrity
    doc=valid_document
    doc['definitions'][0]['root_zone_id']=uuid(999)
    error('E_REFERENCE_MISSING',doc)
    doc=valid_document
    doc['definitions'][0]['zones'] << leaf(3)
    error('E_DUPLICATE_ID',doc)
    doc=chain(2)
    doc['definitions'][0]['zones'][0]['children'][0]['zone_id']=uuid(999)
    error('E_REFERENCE_MISSING',doc)
    doc=chain(2)
    doc['definitions'][0]['zones'][0]['children'][0]['slot_id']=uuid(999)
    error('E_REFERENCE_MISSING',doc)
    doc=valid_document
    doc['definitions'][0]['zones'] << leaf(9)
    error('E_ZONE_UNREACHABLE',doc)
    doc=chain(2)
    partition(doc['definitions'][0]['zones'][1],[3])
    error('E_ZONE_CYCLE',doc)
    doc=chain(1)
    partition(doc['definitions'][0]['zones'][0],[3])
    error('E_ZONE_CYCLE',doc)
    doc=star(3)
    zones=doc['definitions'][0]['zones']
    zones << leaf(6)
    partition(zones[1],[6]); partition(zones[2],[6])
    error('E_ZONE_MULTIPLE_PARENTS',doc)
  end
  def test_slots_layers_and_roles_are_structural_not_geometry
    doc=chain(2)
    z=doc['definitions'][0]['zones'][0]
    z['layout']['slots'][0]['role']='reservation'
    error('E_INPUT_CONTRACT',doc)
    doc=chain(2)
    doc['definitions'][0]['zones'][0]['children']=[]
    error('E_REFERENCE_MISSING',doc)
    doc=star(3)
    z=doc['definitions'][0]['zones'][0]
    z['layout']['slots'][1]['id']=z['layout']['slots'][0]['id']
    error('E_DUPLICATE_ID',doc)
    doc=chain(2)
    z=doc['definitions'][0]['zones'][0]
    z['layout']={'kind'=>'leaf'}
    error('E_INPUT_CONTRACT',doc)
    doc=valid_document
    doc['definitions'][0]['zones'][0]['layout']={'kind'=>'independent_layers','placements'=>[]}
    assert result(doc)[:ok]
    doc=chain(2)
    z=doc['definitions'][0]['zones'][0]
    id=z['children'][0]['slot_id']
    expr={'grammar_version'=>'jp-core-v1','source'=>'-100mm','expected_type'=>'Length'}
    z['layout']={'kind'=>'independent_layers','placements'=>[{'id'=>id,'bounds'=>{'u'=>[expr,expr],'v'=>[expr,expr],'w'=>[expr,expr]}}]}
    assert result(doc)[:ok], 'containment is deferred, not silently evaluated by this codec'
  end
  def test_limits_and_depth_are_checked_without_recursion_or_expansion
    assert result(chain(32))[:ok]
    error('E_RESOURCE_LIMIT',chain(33))
    assert result(star(100,100))[:ok]
    error('E_RESOURCE_LIMIT',star(101,100))
    error('E_RESOURCE_LIMIT',star(2),{zones:1})
    error('E_RESOURCE_LIMIT',star(1,2),{articles:1})
    error('E_RESOURCE_LIMIT',valid_document,{parameters:2})
    doc=valid_document
    doc['definitions'] << doc['definitions'][0].merge('version'=>2)
    error('E_RESOURCE_LIMIT',doc,{definitions:1})
    error('E_RESOURCE_LIMIT',valid_document,{work:2})
  end
end
