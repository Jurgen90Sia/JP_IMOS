require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'
require_relative '../../lib/jp_imos_pro/zones/frame'

class ZoneFrameTest < Minitest::Test
  F=JPImosPro::Zones::Frame
  C=JPImosPro::ProjectCore
  def budget
    C::CoreBudget.new({})
  end
  def test_named_frames_preserve_the_box_with_exact_signed_bases
    b=budget
    root=F.plan(extents:[600,560,720],budget:b)
    front=F.orient(frame:root,orientation:'front',budget:b)
    assert_equal [0,560,0],front[:origin]
    assert_equal [[1,0,0],[0,0,1],[0,-1,0]],front[:basis]
    assert_equal [600,720,560],front[:extents]
    twice=F.child(parent:front,offset:[0,0,0],extents:front[:extents],orientation:'front',budget:b)[:article_frame]
    assert_equal [0,560,720],twice[:origin]
    assert_equal [[1,0,0],[0,-1,0],[0,0,-1]],twice[:basis]
    assert_equal [560,720,600],F.orient(frame:root,orientation:'left_side',budget:b)[:extents]
    assert front[:origin].frozen?
    assert front[:basis][0].frozen?
  end
  def test_composition_fractional_coordinates_and_overflow
    b=budget
    root=F.plan(extents:[600,560,720],budget:b)
    child=F.child(parent:root,offset:[Rational(1,3),0,0],extents:[Rational(2,3),560,720],orientation:'plan',budget:b)
    assert_equal [1,0,0],F.map_point(frame:child[:article_frame],point:[Rational(2,3),0,0],budget:b)
    assert_equal [Rational(1,3),0,0],child[:local_frame][:origin]
    e=assert_raises(C::Fault) { F.orient(frame:root,orientation:'mirror',budget:b) }
    assert_equal 'E_FRAME_UNSUPPORTED',e.code
    large=(1<<4096)-1
    frame={origin:[large,0,0],basis:root[:basis],extents:root[:extents]}
    e=assert_raises(C::Fault) { F.map_point(frame:frame,point:[large,0,0],budget:b) }
    assert_equal 'E_RESOURCE_LIMIT',e.code
    e=assert_raises(C::Fault) { F.plan(extents:[1.0,2,3],budget:b) }
    assert_equal 'E_FRAME_UNSUPPORTED',e.code
  end
end
