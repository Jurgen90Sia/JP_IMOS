# Test-only mutable tree. It is not a native SketchUp adapter.
class HostTreeModel
  attr_accessor :document,:roots
  def initialize
    @document=nil;@roots=[]
  end
end

class HostTreePort
  attr_reader :anchor,:controlled_grant
  attr_accessor :on_inspect,:edit_path,:mapping_override
  def initialize(model,anchor)
    @model,@anchor=model,anchor;@pid=10;@edit_path=false
  end
  def settle(context)
    @controlled_grant=JPImosPro::Host::Registry.issue_grant(context:context)
  end
  def document_json;@model.document;end
  def edit_path_open?;@edit_path;end
  def node(kind,tag,children=[])
    @pid+=1
    {kind:kind,tag:tag,children:children,pid:@pid.to_s,transform:[0,0,0],locked:false}
  end
  def install_fixture(state,policy,root_id,acceptance)
    p=JPImosPro::Host::Projection.build(state:state,numeric_policy:policy)[:value]
    parts=p.plan['parts'].map do |part|
      solids=part['solids'].map do |s|
        n=node(:solid,{kind:'solid',root_id:root_id,part_id:part['part_id'],component:s['component'],source_index:s['source_index']})
        n[:vertices]=s['world_vertices'].map { |v| v.map { |d| JPImosPro::Zones::EngineBridge.rational(d) } }
        n[:faces]=s['face_loops'].values.map(&:dup);n
      end
      node(:part,{kind:'part',root_id:root_id,part_id:part['part_id']},solids)
    end
    @model.roots=parts.empty? ? [] : [node(:root,{kind:'root',root_id:root_id,project_id:p.plan['project_id']},parts)]
    m={'schema'=>'jpimos.host-manifest/1','plan_sha256'=>p.plan_sha256,'root_pid_hint'=>nil,
      'parts'=>p.plan['parts'].map { |part| {'part_id'=>part['part_id'],'container_pid_hint'=>nil,
        'solids'=>part['solids'].map { |s| {'component'=>s['component'],'source_index'=>s['source_index'],'pid_hint'=>nil} }} }}
    r=JPImosPro::Host::DocumentCodec.encode(state:state,root_id:parts.empty? ? nil : root_id,acceptance_id:acceptance,manifest:m,numeric_policy:policy)
    raise r[:diagnostics].inspect unless r[:ok]
    @model.document=r[:value]
  end
  def fail!(code='E_HOST_OWNERSHIP_CONFLICT')
    raise JPImosPro::ProjectCore::Fault.new(code,'/host/tree')
  end
  def scan(budget)
    tagged=[];stack=@model.roots.map { |n| [n,{}] }
    until stack.empty?
      n,ancestors=stack.pop;budget.tick
      fail! if ancestors[n.object_id]
      tagged << n if n[:tag]
      chain=ancestors.merge(n.object_id=>true)
      n[:children].each { |child| stack << [child,chain] }
    end
    tagged
  end
  def inspect_empty(budget:)
    fail! unless scan(budget).empty?
    @on_inspect.call if @on_inspect
    JPImosPro::Host::Inspection.from_port(root_handle:nil,manifest:nil)
  end
  def inspect_projection(plan:,root_id:,manifest:,budget:,staging:nil)
    tagged=scan(budget)
    return inspect_empty(budget:budget) if plan['parts'].empty?
    roots=@model.roots.select { |n| n[:tag]=={kind:'root',root_id:root_id,project_id:plan['project_id']} }
    fail! unless roots.size==1
    root=roots[0];check_node(root,:root,budget)
    fail! unless root[:children].size==plan['parts'].size
    used=[root];mapped=[]
    plan['parts'].each do |part|
      matches=root[:children].select { |n| n[:tag]=={kind:'part',root_id:root_id,part_id:part['part_id']} }
      fail! unless matches.size==1
      container=matches[0];check_node(container,:part,budget);used << container
      fail! unless container[:children].size==part['solids'].size
      solids=part['solids'].map do |s|
        tag={kind:'solid',root_id:root_id,part_id:part['part_id'],component:s['component'],source_index:s['source_index']}
        matches=container[:children].select { |n| n[:tag]==tag };fail! unless matches.size==1
        actual=matches[0];check_node(actual,:solid,budget);used << actual
        fail! unless actual[:children].empty?
        budget.tick(actual[:vertices].size+actual[:faces].size)
        points=s['world_vertices'].map { |v| v.map { |d| JPImosPro::Zones::EngineBridge.rational(d) } }
        fail!('E_HOST_GEOMETRY_CONFLICT') unless actual[:vertices]==points
        expected=s['face_loops'].values
        valid=actual[:faces].size==6 && expected.all? do |face|
          actual[:faces].count { |a| a.size==4 && 4.times.any? { |i| a.rotate(i)==face } }==1
        end
        fail!('E_HOST_GEOMETRY_CONFLICT') unless valid
        {'component'=>s['component'],'source_index'=>s['source_index'],'pid_hint'=>actual[:pid]}
      end
      mapped << {'part_id'=>part['part_id'],'container_pid_hint'=>container[:pid],'solids'=>solids}
    end
    fail! unless tagged.size==used.size && (tagged-used).empty?
    m={'schema'=>'jpimos.host-manifest/1','plan_sha256'=>manifest['plan_sha256'],'root_pid_hint'=>root[:pid],'parts'=>mapped}
    m=@mapping_override unless @mapping_override.nil?
    @on_inspect.call if @on_inspect
    JPImosPro::Host::Inspection.from_port(root_handle:root,manifest:m)
  end
  def check_node(n,kind,budget)
    budget.tick;fail! unless n[:kind]==kind && !n[:locked]
    fail!('E_HOST_GEOMETRY_CONFLICT') unless n[:transform]==[0,0,0]
  end
end
