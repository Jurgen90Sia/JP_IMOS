require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/construction'
require_relative 'fixtures'
class CarcassPreviewTest < Minitest::Test
  include CarcassFixtures
  def preview(doc=valid_document,req=request,limits={})
    JPImosPro::Construction.build_carcass(document:doc,request:req,numeric_policy:policy,limits:limits)
  end
  def volume(panel)
    v=panel['geometry']['finished_envelope_volume']['numeric'];Rational(v['numerator'],v['denominator'])
  end
  def test_preview_has_four_nonintersecting_finished_panels_in_the_envelope
    r=preview
    assert r[:ok],r[:diagnostics].inspect
    p=r[:value]
    assert_equal [564,560,684],rationals(p['reference_opening']['extents'])
    assert_equal 4,p['panels'].size
    assert_equal 25885440,p['panels'].sum { |panel| volume(panel) }
    p['panels'].each do |panel|
      panel['geometry']['article_vertices'].each do |point|
        rationals(point).zip([600,560,720]).each { |x,max| assert x>=0 && x<=max }
      end
    end
    p['panels'].combination(2) do |a,b|
      amin=rationals(a['geometry']['bbox_min']);amax=rationals(a['geometry']['bbox_max'])
      bmin=rationals(b['geometry']['bbox_min']);bmax=rationals(b['geometry']['bbox_max'])
      overlap=3.times.map { |i| [[amax[i],bmax[i]].min-[amin[i],bmin[i]].max,0].max }.inject(1,:*)
      assert_equal 0,overlap
    end
    assert p.frozen?
    assert p['construction_request']['panels']['left'].frozen?
  end
  def test_context_hashes_and_identity_bind_every_authoring_input
    doc=valid_document;req=request
    a=preview(doc,req);assert a[:ok]
    reordered=req.to_a.reverse.to_h
    assert_equal a[:value]['source_context'],preview(doc,reordered)[:value]['source_context']
    req['panels']['left']['finished_substrate_thickness']=length(19)
    b=preview(doc,req);assert b[:ok]
    refute_equal a[:value]['source_context']['request_sha256'],b[:value]['source_context']['request_sha256']
    doc['articles'][0]['parameter_values']['W']=length(800)
    c=preview(doc,req);assert c[:ok]
    refute_equal b[:value]['source_context']['project_document_sha256'],c[:value]['source_context']['project_document_sha256']
    assert_equal b[:value]['panels'].map { |x| x['occurrence_ref'] },c[:value]['panels'].map { |x| x['occurrence_ref'] }
    refute doc.frozen?
    refute req.frozen?
  end
  def test_selected_reference_envelope_is_independent_of_view_and_project_translation
    doc=valid_document
    doc['definitions'][0]['zones'][0]['orientation']='front'
    doc['articles'][0]['origin']=[length(10),length(20),length(30)]
    r=preview(doc);assert r[:ok]
    assert_equal [600,560,720],rationals(r[:value]['reference_envelope']['extents'])
    assert_equal [10,20,30],rationals(r[:value]['article_origin'])
    assert_equal [582,0,0],rationals(r[:value]['panels'][1]['geometry']['bbox_min'])
    doc['articles'] << Marshal.load(Marshal.dump(doc['articles'][0])).merge('id'=>uuid(50))
    req=request;req['article_instance_id']=uuid(50)
    b=preview(doc,req);assert b[:ok]
    refute_equal r[:value]['panels'][0]['occurrence_ref'],b[:value]['panels'][0]['occurrence_ref']
  end
  def test_invalid_input_is_atomic_and_does_not_hide_bad_sibling_zones
    req=request;req['article_instance_id']=uuid(999)
    error('E_REFERENCE_MISSING',preview(valid_document,req))
    doc=valid_document;doc['articles'][0]['parameter_values']['W']=length(36)
    error('E_INFEASIBLE_CONSTRUCTION',preview(doc))
    req=request;req['principle']='unknown'
    error('E_CONSTRUCTION_UNSUPPORTED',preview(valid_document,req))
    req=request;req['panels']['left']['finished_substrate_thickness']=length(0)
    error('E_DOMAIN',preview(valid_document,req))
    assert preview[:ok]
  end
  def test_finished_surfaces_and_fractional_dimensions_stay_exact
    req=request
    req['panels']['left']['finished_substrate_thickness']=length(37,2)
    req['panels']['left']['dimensional_surfaces']=[surface('near',1,2),surface('far',1,2)]
    r=preview(valid_document,req);assert r[:ok],r[:diagnostics].inspect
    assert_equal [Rational(1125,2),560,684],rationals(r[:value]['reference_opening']['extents'])
    assert_equal 26460000,r[:value]['panels'].sum { |panel| volume(panel) }
    assert_equal [Rational(39,2),560,720],rationals(r[:value]['panels'][0]['geometry']['bbox_max'])
    doc=valid_document
    %w[W D H].zip([1201,1121,1441]).each { |key,n| doc['articles'][0]['parameter_values'][key]=length(n,2) }
    r=preview(doc);assert r[:ok]
    assert_equal [Rational(1129,2),Rational(1121,2),Rational(1369,2)],rationals(r[:value]['reference_opening']['extents'])
    assert_equal 25928730,r[:value]['panels'].sum { |panel| volume(panel) }
    req=request
    req['panels']['right']=characteristic(20,21)
    req['panels']['top']=characteristic(16,19)
    req['panels']['bottom']=characteristic(22,25)
    r=preview(valid_document,req);assert r[:ok]
    assert_equal [580,0,0],rationals(r[:value]['panels'][1]['geometry']['bbox_min'])
    assert_equal [18,0,704],rationals(r[:value]['panels'][2]['geometry']['bbox_min'])
    assert_equal [580,560,22],rationals(r[:value]['panels'][3]['geometry']['bbox_max'])
    assert_equal 27280960,r[:value]['panels'].sum { |panel| volume(panel) }
  end
  def test_full_project_sibling_errors_and_shared_limits_are_atomic
    doc=partition(valid_document,'1/$a:1')
    doc['definitions'][0]['parameters'] << {'name'=>'a','expected_type'=>'Scalar','default_value'=>scalar(1),'required'=>false}
    sibling=Marshal.load(Marshal.dump(doc['articles'][0])).merge('id'=>uuid(50))
    sibling['parameter_values']['a']=scalar(0);doc['articles'] << sibling
    r=preview(doc)
    error('E_DIV_ZERO',r)
    assert_equal '/document/definitions/0/zones/0/layout/expression/source',r[:diagnostics][0][:json_pointer]
    assert_equal uuid(50),r[:diagnostics][0][:entity_ref]['article_instance_id']
    assert JPImosPro::ProjectCore.encode_document(document:valid_document,limits:{work:1000})[:ok]
    r=preview(valid_document,request,{work:1000})
    error('E_RESOURCE_LIMIT',r)
    assert_equal r[:diagnostics],preview(valid_document,request,{work:1000})[:diagnostics]
    assert preview[:ok]
    error('E_INPUT_CONTRACT',JPImosPro::Construction.build_carcass(document:valid_document,request:request,numeric_policy:nil))
    doc=valid_document
    doc['articles'][0]['parameter_values']['W']=length(1<<2048)
    doc['articles'][0]['parameter_values']['D']=length(1<<2048)
    error('E_RESOURCE_LIMIT',preview(doc))
  end
end
