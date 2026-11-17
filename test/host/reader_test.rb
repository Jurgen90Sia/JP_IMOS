require_relative 'session_support'
class HostReaderTest < Minitest::Test
  include HostSessionSupport
  def test_manual_geometry_foreign_child_copied_root_and_orphan_are_refused
    changes=[
      -> { @model.roots[0][:transform]=[100,0,0] },
      -> { @model.roots[0][:children][0][:children][0][:faces][0]=[0,1,2,4] },
      -> { @model.roots[0][:children][0][:children][0][:vertices][0][0]+=1 },
      -> { @model.roots[0][:children] << @port.node(:foreign,nil) },
      -> { @model.roots << Marshal.load(Marshal.dump(@model.roots[0])) },
      -> { @model.roots << @port.node(:part,{kind:'part',root_id:uuid(99),part_id:uuid(98)}) },
      -> { @model.roots[0][:locked]=true }]
    changes.each do |change|
      @port.install_fixture(physical_state,policy,uuid(2000),uuid(2001))
      original=@model.document.dup;change.call;r=read
      refute r[:ok],change.inspect
      assert_nil r[:value]
      assert_includes %w[E_HOST_OWNERSHIP_CONFLICT E_HOST_GEOMETRY_CONFLICT],r[:diagnostics][0][:code]
      assert_equal original,@model.document
      assert_equal 'unchanged',r[:metadata][:mutation_state]
    end
  end
  def test_stale_hints_are_updated_in_memory_without_rewriting_document
    @port.install_fixture(physical_state,policy,uuid(2000),uuid(2001));original=@model.document.dup
    @model.roots[0][:pid]='999'
    @model.roots << @port.node(:foreign,nil)
    l=lease
    assert_nil l.document['projection']['root_pid_hint']
    assert_equal '999',l.inspection.manifest['root_pid_hint']
    assert_equal original,@model.document
    assert_equal Digest::SHA256.hexdigest(original),l.raw_sha256
    assert_equal original,l.raw_document
  end
  def test_accepted_empty_is_distinct_from_an_unaccepted_empty_model
    fresh=lease;assert_nil fresh.document;assert_nil fresh.projection
    state=physical_state;state['design']['project']['articles']=[];state['design']['construction_requests']=[];state['part_policies']=[]
    l=accepted(state);refute_nil l.document;assert_nil l.document['root_id']
    error('E_HOST_OWNERSHIP_CONFLICT',initial(l))
    @model.document=nil;@model.roots << @port.node(:root,{kind:'root',root_id:uuid(2),project_id:uuid(1)})
    error('E_HOST_OWNERSHIP_CONFLICT',read)
  end
  def test_edit_context_bad_resources_and_wrong_thread_fail_before_inspection
    @port.edit_path=true
    error('E_HOST_EDIT_CONTEXT',read)
    @port.edit_path=false
    @port.install_fixture(physical_state,policy,uuid(2000),uuid(2001))
    error('E_RESOURCE_LIMIT',read(@context,{entity_visits:1}))
    error('E_RESOURCE_LIMIT',read(@context,{work:100}))
    error('E_INPUT_CONTRACT',read(@context,{entity_visits:50001}))
    @port.settle(@context)
    error('E_HOST_CONTEXT_UNSUPPORTED',Thread.new { JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy) }.value)
    assert read[:ok]
  end
  def test_invalidation_or_source_change_during_inspection_cannot_publish_lease
    accepted;@port.on_inspect=-> { @context.authority.notify_external! }
    error('E_HOST_LEASE_CONFLICT',read)
    assert @context.authority.quarantined?
    @port.on_inspect=nil
    @port.settle(@context)
    assert JPImosPro::Host::Recovery.read(context:@context,fresh_grant:@port.controlled_grant,numeric_policy:policy)[:ok]
    @port.on_inspect=-> { @model.document=@model.document+' ' }
    error('E_HOST_LEASE_CONFLICT',read)
    assert @context.authority.quarantined?
  end
  def test_cyclic_tree_scan_is_bounded_and_read_does_not_repair
    node=@port.node(:foreign,nil);node[:children] << node;@model.roots << node
    error('E_HOST_OWNERSHIP_CONFLICT',read)
    assert_nil @model.document
    assert_same node,@model.roots[0][:children][0]
  end
  def test_port_mapping_must_pass_bounded_manifest_validation_before_publication
    accepted
    mapping=JSON.parse(@model.document)['projection'];mapping['root_pid_hint']='01'
    @port.mapping_override=mapping
    error('E_INPUT_CONTRACT',read)
    mapping['root_pid_hint']='123'
    l=lease
    mapping['root_pid_hint'].replace('999')
    assert_equal '123',l.inspection.manifest['root_pid_hint']
    assert l.inspection.manifest.frozen?
  end
  def test_port_exception_returns_typed_failure_and_preserves_quarantine
    accepted;before=@model.document.dup
    @port.on_inspect=-> { raise RuntimeError,'synthetic port inspection failure' }
    r=read
    error('E_HOST_CONTEXT_UNSUPPORTED',r)
    assert_equal 'unchanged',r[:metadata][:mutation_state]
    assert @context.authority.quarantined?
    assert_equal before,@model.document
  end
end
