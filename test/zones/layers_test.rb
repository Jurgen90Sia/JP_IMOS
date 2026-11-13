require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative 'fixtures'
class ZoneLayersTest < Minitest::Test
  include ZoneFixtures
  def change(doc,source,endpoint=0,axis='u',i=0)
    doc['definitions'][0]['zones'][0]['layout']['placements'][i]['bounds'][axis][endpoint]['source']=source
    doc
  end
  def test_coextensive_layers_do_not_consume_siblings_space
    doc=layers
    z=zones(resolve(doc))
    assert_equal [[600,560,720],[600,560,720]],z[1..-1].map { |x| rationals(x['local_extents']) }
    refute_equal z[1]['occurrence_ref'],z[2]['occurrence_ref']
    doc['definitions'][0]['zones'][1]['orientation']='front'
    z=zones(resolve(doc))
    assert_equal [600,720,560],rationals(z[1]['local_extents'])
    assert_equal [0,560,0],rationals(z[1]['article_origin'])
    assert_equal [600,560,720],rationals(z[2]['local_extents'])
    doc['definitions'][0]['zones'][0]['children'].reverse!
    z=zones(resolve(doc))
    assert_equal uuid(11),z[1]['authored_zone_id']
    assert_equal [600,560,720],rationals(z[1]['local_extents'])
  end
  def test_containment_is_exact_without_epsilon_or_clipping
    [['-1mm',0],['601mm',1],['0mm',1],['(-1/10000)mm',0]].each do |source,endpoint|
      error('E_ZONE_CONTAINMENT',resolve(change(layers,source,endpoint)))
    end
    doc=change(layers,'(1/3)mm')
    z=zones(resolve(doc))
    assert_equal [Rational(1,3),0,0],rationals(z[1]['article_origin'])
    assert_equal [Rational(1799,3),560,720],rationals(z[1]['local_extents'])
    assert_equal [],zones(resolve(layers(0)))[0]['occupied_slots']
  end
  def test_endpoint_types_exactness_and_full_declaration_validation
    error('E_UNIT_MISMATCH',resolve(change(layers,'0')))
    error('E_INEXACT_DIVISION_INPUT',resolve(change(layers,'(sin(pi/2))mm')))
    error('E_UNKNOWN_SYMBOL',resolve(change(layers,'if(true,0mm,missing)')))
    doc=partition(valid_document,'$n:1')
    doc['definitions'][0]['parameters'] << {'name'=>'n','expected_type'=>'Scalar','default_value'=>scalar(1),'required'=>false}
    assert_equal [300,560,720],rationals(zones(resolve(doc))[1]['local_extents'])
    doc['definitions'][0]['zones'][0]['layout']['expression']['source']='n:1'
    error('E_UNSUPPORTED_GRAMMAR',resolve(doc))
  end
end
