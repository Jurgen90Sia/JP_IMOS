require_relative 'session_support'
class HostSessionTest < Minitest::Test
  include HostSessionSupport
  def test_registry_entry_point_exists
    assert defined?(JPImosPro::Host::Registry),'missing shared session authority'
  end
  def test_attachments_share_authority_guard_and_read_sequence
    c2=JPImosPro::Host::Registry.attach(port:HostTreePort.new(@model,@anchor))
    assert_same @context.authority,c2.authority
    l=lease;r=read(c2);assert r[:ok],r[:diagnostics].inspect
    assert_operator r[:value].sequence,:>,l.sequence
    error('E_HOST_LEASE_CONFLICT',initial(l))
    @context.authority.with_guard do
      error('E_HOST_REENTRANT',read(c2))
    end
    assert initial(r[:value])[:ok]
  end
  def test_copied_marshaled_cross_model_and_closed_incarnation_objects_refused
    l=lease
    error('E_HOST_LEASE_CONFLICT',initial(l.dup))
    assert_raises(TypeError) { Marshal.dump(l) }
    c=candidate
    @context.authority.validate_candidate(c)
    assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.validate_candidate(c.dup) }
    model2=HostTreeModel.new;anchor2=JPImosPro::Host::Registry.open(model:model2)
    context2=JPImosPro::Host::Registry.attach(port:HostTreePort.new(model2,anchor2))
    assert_raises(JPImosPro::ProjectCore::Fault) { context2.authority.validate_candidate(c) }
    JPImosPro::Host::Registry.close(anchor:anchor2)
    JPImosPro::Host::Registry.close(anchor:@anchor)
    reopened=JPImosPro::Host::Registry.open(model:@model)
    refute_same @anchor,reopened
    @anchor=reopened
    error('E_HOST_LEASE_CONFLICT',initial(c.base_lease))
  end
  def test_gateway_aba_and_consumption_never_revive_old_candidates
    l=accepted;c=revision(l,resize)[:value];refute_nil c
    original=@model.document.dup
    @context.authority.before_action!
    @model.document=original.dup # undo/redo restores identical bytes
    error('E_HOST_QUIESCENCE_UNPROVEN',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
    assert read[:ok]
    assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.validate_candidate(c) }
    c=revision(lease,resize)[:value]
    @context.authority.consume_candidate(c)
    assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.consume_candidate(c) }
  end
  def test_preparation_reuses_physical_guards_policy_and_revision
    l=accepted;r=revision(l,resize);assert r[:ok],r[:diagnostics].inspect
    c=r[:value];assert c.frozen?
    assert_equal 8,c.projection.plan['source_revision']
    assert_equal l.projection.plan['parts'].map { |p| p['part_id'] },c.projection.plan['parts'].map { |p| p['part_id'] }
    assert_equal '764',c.projection.snapshot['parts'][2]['part']['finished_dimensions'][0]['numeric']['numerator']
    error('E_REVISION_CONFLICT',revision(l,resize,6))
    error('E_NO_CHANGE',revision(l))
    error('E_NUMERIC_POLICY_CONFLICT',revision(l,resize,7,{policy_id:policy[:policy_id],backend_id:'different'}))
    error('E_HOST_OWNERSHIP_CONFLICT',initial(l))
    bad=resize;bad['part_policies'][0]['id']=uuid(9999)
    refute revision(l,bad)[:ok]
    assert_equal 7,l.projection.plan['source_revision']
    assert_raises(TypeError) { Marshal.dump(c) }
  end
  def test_quarantine_survives_attachment_and_ordinary_read_requires_explicit_fresh_recovery
    accepted;@context.authority.quarantine!
    another=JPImosPro::Host::Registry.attach(port:HostTreePort.new(@model,@anchor))
    l=read(another)[:value];refute_nil l;assert l.read_only?
    error('E_HOST_RECOVERY_REQUIRED',revision(l,resize))
    old_grant=another.port.controlled_grant
    error('E_HOST_QUIESCENCE_UNPROVEN',JPImosPro::Host::Recovery.read(context:another,fresh_grant:old_grant,numeric_policy:policy))
    @model.roots[0][:transform]=[1,0,0]
    grant=another.port.settle(another)
    failed=JPImosPro::Host::Recovery.read(context:another,fresh_grant:grant,numeric_policy:policy)
    error('E_HOST_GEOMETRY_CONFLICT',failed)
    assert @context.authority.quarantined?
    @model.roots[0][:transform]=[0,0,0];before=@model.document.dup
    grant=another.port.settle(another)
    r=JPImosPro::Host::Recovery.read(context:another,fresh_grant:grant,numeric_policy:policy)
    assert r[:ok],r[:diagnostics].inspect
    refute r[:value].read_only?
    refute @context.authority.quarantined?
    assert_equal before,@model.document
    assert_equal 'unchanged',r[:metadata][:mutation_state]
    assert revision(r[:value],resize)[:ok]
    assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.validate_lease(l) }
  end
  def test_uncontrolled_notification_invalidates_and_quarantines
    c=candidate;@context.authority.notify_external!
    assert @context.authority.quarantined?
    assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.validate_candidate(c) }
    error('E_HOST_RECOVERY_REQUIRED',initial(read[:value]))
  end
  def test_owned_source_only_and_budget_refusal
    l=lease
    p=JPImosPro::Host::Projection.build(state:physical_state,numeric_policy:policy)[:value]
    error('E_SCHEMA_UNSUPPORTED',initial(l,p.snapshot))
    bad=physical_state;bad['part_policies'][0]['frame']={}
    error('E_INPUT_CONTRACT',initial(l,bad))
    error('E_RESOURCE_LIMIT',initial(l,physical_state,{work:100}))
    assert initial(l)[:ok]
  end
  def test_identical_file_clone_cannot_accept_another_model_candidate
    l=accepted;c=revision(l,resize)[:value]
    model2=HostTreeModel.new;model2.document=@model.document.dup;model2.roots=Marshal.load(Marshal.dump(@model.roots))
    anchor2=JPImosPro::Host::Registry.open(model:model2)
    context2=JPImosPro::Host::Registry.attach(port:HostTreePort.new(model2,anchor2))
    begin
      clone=read(context2);assert clone[:ok],clone[:diagnostics].inspect
      assert_equal l.raw_sha256,clone[:value].raw_sha256
      assert_raises(JPImosPro::ProjectCore::Fault) { context2.authority.validate_candidate(c) }
      assert_raises(NoMethodError) { JPImosPro::Host::Context.new }
      assert_raises(NoMethodError) { JPImosPro::Host::Lease.new }
      assert_raises(NoMethodError) { JPImosPro::Host::Candidate.new }
      error('E_HOST_CONTEXT_UNSUPPORTED',JPImosPro::Host::Reader.read(context:context2.dup,numeric_policy:policy))
    ensure
      JPImosPro::Host::Registry.close(anchor:anchor2)
    end
  end
  def test_visit_budget_cannot_be_lowered_by_negative_charges
    b=JPImosPro::Host::VisitBudget.new(2)
    assert_raises(JPImosPro::ProjectCore::Fault) { b.tick(-1) }
    assert_equal 0,b.used
    b.tick(2)
    assert_raises(JPImosPro::ProjectCore::Fault) { b.tick }
  end
end
