require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'
class ZoneResolverTest < Minitest::Test
  include ZoneFixtures
  def test_equal_partitions_and_explicit_reservations
    z=zones(resolve(partition(valid_document,'1:1')))
    assert_equal [300,560,720],rationals(z[1]['local_extents'])
    assert_equal [300,0,0],rationals(z[2]['article_origin'])
    doc=partition(valid_document,'1:18mm:1',['zone','reservation','zone'])
    z=zones(resolve(doc))
    assert_equal 3,z.size
    assert_equal [291,560,720],rationals(z[1]['local_extents'])
    assert_equal [309,0,0],rationals(z[2]['article_origin'])
    assert_equal 'reservation',z[0]['occupied_slots'][1]['role']
    assert_equal [18],rationals([z[0]['occupied_slots'][1]['length']])
    doc['definitions'][0]['zones'][0]['children'].reverse!
    z=zones(resolve(doc))
    assert_equal uuid(12),z[1]['authored_zone_id']
    assert_equal [309,0,0],rationals(z[1]['article_origin'])
  end
  def test_orientations_nested_partition_and_translation
    doc=partition(valid_document,'1:2',['zone','zone'],'v')
    doc['definitions'][0]['zones'][0]['orientation']='front'
    z=zones(resolve(doc))
    assert_equal [0,560,0],rationals(z[0]['article_origin'])
    assert_equal [600,240,560],rationals(z[1]['local_extents'])
    assert_equal [0,560,240],rationals(z[2]['article_origin'])
    doc=partition(valid_document,'1:1')
    doc['definitions'][0]['zones'][0]['orientation']='left_side'
    z=zones(resolve(doc))
    assert_equal [280,720,600],rationals(z[1]['local_extents'])
    assert_equal [0,280,0],rationals(z[2]['article_origin'])
    doc=partition(valid_document,'1:1')
    doc['articles'][0]['origin']=[length(10),length(20),length(30)]
    r=resolve(doc); z=zones(r)
    assert_equal [300,0,0],rationals(z[2]['article_origin'])
    assert_equal [310,20,30],rationals(r[:value]['articles'][0]['origin']).zip(rationals(z[2]['article_origin'])).map { |a,b| a+b }
    child=doc['definitions'][0]['zones'][1]
    child['layout']={'kind'=>'partition','axis'=>'w','expression'=>{'grammar_version'=>'jp-division-v1','source'=>'1:2'},'slots'=>[{'id'=>uuid(200),'role'=>'zone'},{'id'=>uuid(201),'role'=>'zone'}]}
    child['children']=[{'zone_id'=>uuid(20),'slot_id'=>uuid(200)},{'zone_id'=>uuid(21),'slot_id'=>uuid(201)}]
    doc['definitions'][0]['zones'] += [leaf(20),leaf(21)]
    z=zones(resolve(doc))
    assert_equal [300,560,240],rationals(z[2]['local_extents'])
    assert_equal [0,0,240],rationals(z[3]['article_origin'])
  end
  def test_topology_resize_external_intervals_and_source_conflict_isolation
    error('E_DEGENERATE_INTERVAL',resolve(partition(valid_document,'0:1:0',['zone']*3)))
    error('E_DEGENERATE_INTERVAL',resolve(partition(valid_document,'-200mm:1:-200mm',['zone']*3)))
    doc=partition(valid_document,'8{1}',['zone']*8)
    assert_equal 9,zones(resolve(doc)).size
    doc['definitions'][0]['zones'][0]['layout']['expression']['source']='7{1}'
    error('E_ZONE_TOPOLOGY_CHANGED',resolve(doc))
    doc=partition(valid_document,'1:1'); before=zones(resolve(doc))
    doc['articles'][0]['parameter_values']['W']=length(800)
    after=zones(resolve(doc))
    assert_equal before.map { |x| x['occurrence_ref'] },after.map { |x| x['occurrence_ref'] }
    assert_equal [400,560,720],rationals(after[1]['local_extents'])
    doc=partition(valid_document,'1:18mm:1:18mm:1',['zone','reservation','zone','reservation','zone'])
    doc['articles'][0]['parameter_values']['W']=length(1500)
    assert_equal [488,488,488],zones(resolve(doc))[1..-1].map { |x| rationals(x['local_extents'])[0] }
  end
  def test_atomic_errors_immutable_occurrences_and_empty_projects
    doc=partition(valid_document,'1:1')
    doc['articles'] << Marshal.load(Marshal.dump(doc['articles'][0])).merge('id'=>uuid(50))
    r=resolve(doc); z=zones(r)
    assert_equal 6,z.size
    refute_equal z[1]['occurrence_ref'],z[4]['occurrence_ref']
    assert r[:value].frozen?
    assert z[0]['article_basis'][0].frozen?
    refute doc.frozen?
    doc['definitions'][0]['zones'][0]['layout']['expression']['source']='1:1/0'
    r=resolve(doc)
    error('E_DIV_ZERO',r)
    d=r[:diagnostics][0]
    assert_equal '/definitions/0/zones/0/layout/expression/source',d[:json_pointer]
    assert_equal 'jp-division-v1',d[:grammar_version]
    assert_equal({start:2,end:5},d[:source_span])
    assert_equal uuid(4),d[:entity_ref]['article_instance_id']
    doc=valid_document; doc['articles']=[]; doc['definitions']=[]
    assert_equal [],zones(resolve(doc))
  end
end
