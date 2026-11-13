require_relative '../project_core/fixtures'
module ZoneFixtures
  include CoreFixtures
  def policy
    {policy_id:'jp-rational-binary64-15-v1',backend_id:"#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math"}
  end
  def partition(doc,source,roles=['zone','zone'],axis='u')
    definition=doc['definitions'][0]
    root=definition['zones'][0]
    root['layout']={'kind'=>'partition','axis'=>axis,'expression'=>{'grammar_version'=>'jp-division-v1','source'=>source},
      'slots'=>roles.each_with_index.map { |role,i| {'id'=>uuid(100+i),'role'=>role} }}
    root['children']=roles.each_with_index.filter_map do |role,i|
      next unless role=='zone'
      definition['zones'] << leaf(10+i)
      {'zone_id'=>uuid(10+i),'slot_id'=>uuid(100+i)}
    end
    doc
  end
  def resolve(doc=valid_document,limits={})
    JPImosPro::ProjectCore.resolve_zones(document:doc,numeric_policy:policy,limits:limits)
  end
  def rationals(values)
    values.map { |v| Rational(v['numeric']['numerator'],v['numeric']['denominator']) }
  end
  def zones(result)
    assert result[:ok],result[:diagnostics].inspect
    result[:value]['zones']
  end
  def error(code,result)
    refute result[:ok]
    assert_nil result[:value]
    assert_equal code,result[:diagnostics][0][:code]
  end
end
