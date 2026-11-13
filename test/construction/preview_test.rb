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
end
