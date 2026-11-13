require 'minitest/autorun'
require_relative '../../lib/jp_imos_pro/project_core'

class ZoneBudgetTest < Minitest::Test
  P = JPImosPro::Parametric
  POLICY = {policy_id:P::POLICY,backend_id:"#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"}.freeze
  def expression(counter)
    P::Internal.expression(source:'1+2',symbols:{},numeric_policy:POLICY,shared_counter:counter)
  end
  def test_individually_valid_requests_share_a_finite_counter
    counter=P::WorkCounter.new(limit:100)
    assert expression(counter)[:ok]
    results=Array.new(20) { expression(counter) }
    assert results.any? { |r| !r[:ok] && r[:diagnostics][0][:code]=='E_RESOURCE_LIMIT' }
    assert expression(P::WorkCounter.new(limit:100))[:ok]
    assert_operator counter.used,:>,0
    assert_raises(P::Fault) { P::WorkCounter.new(limit:100001) }
    assert_raises(P::Fault) { P::Budget.new({},shared_counter:Object.new) }
    assert_raises(P::Fault) { P::Budget.new({},shared_counter:false) }
    assert_raises(P::Fault) { expression(nil) }
    roomy=P::WorkCounter.new(limit:100000)
    local=P::Budget.new({steps:1},shared_counter:roomy)
    e=assert_raises(P::Fault) { local.tick(2) }
    assert_equal 'E_RESOURCE_LIMIT',e.code
    assert_equal 2,roomy.used
  end
  def test_core_and_engine_spend_the_same_request_budget
    core=JPImosPro::ProjectCore::CoreBudget.new(work:100)
    core.tick('',95)
    refute expression(core.counter)[:ok]
    assert_raises(JPImosPro::ProjectCore::Fault) { core.tick('/x') }
    reference={length:{type:'Length',unit:'mm',numeric:{numerator:'800',denominator:'1',exact:true}},origin:{type:'Length',unit:'mm',numeric:{numerator:'0',denominator:'1',exact:true}},direction:1}
    r=P::Internal.division(source:'8{1}',reference:reference,symbols:{},context:'positive_intervals',numeric_policy:POLICY,shared_counter:P::WorkCounter.new(limit:10))
    assert_equal 'E_RESOURCE_LIMIT',r[:diagnostics][0][:code]
  end
end
