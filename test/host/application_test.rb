require_relative 'session_support'
require 'minitest/mock'
path=File.expand_path('../../lib/jp_imos_pro/host/application.rb',__dir__)
require path if File.exist?(path)
class HostApplicationTest < Minitest::Test
  include HostSessionSupport
  def apply(c=candidate,limits={},context=@context)
    JPImosPro::Host::Application.apply(context:context,candidate:c,limits:limits)
  end
  def capture
    Marshal.dump([@model.document,@model.roots,@model.extras])
  end
  def mark_unrelated
    @model.extras={'probe_dictionary'=>{'draft'=>'preserve'},'user_note'=>'untouched'}
    @sentinel=@port.node(:foreign,nil)
    @model.roots << @sentinel
  end
  def assert_failure(result,code,mutation)
    error(code,result)
    assert_equal mutation,result[:metadata][:mutation_state]
  end
  def test_controller_entry_point_exists
    assert defined?(JPImosPro::Host::Application),'missing atomic transaction controller'
  end
  def test_initial_apply_commits_matching_source_geometry_and_preserves_unrelated
    mark_unrelated;c=candidate;r=apply(c)
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 'committed',r[:metadata][:mutation_state]
    l=r[:value];assert_equal 7,l.projection.plan['source_revision']
    assert_equal @model.document,l.raw_document
    assert_equal c.projection.plan_sha256,l.document['projection']['plan_sha256']
    assert_same @sentinel,@model.roots.find { |n| n[:tag].nil? }
    assert_equal 'preserve',@model.extras['probe_dictionary']['draft']
    assert_equal 1,@port.calls[:begin];assert_equal 1,@port.calls[:commit];assert_equal 0,@port.calls[:abort]
    assert_failure(apply(c),'E_HOST_LEASE_CONFLICT','unchanged')
    decoded=JPImosPro::Host::DocumentCodec.decode(source:@model.document,numeric_policy:policy)
    assert decoded[:ok],decoded[:diagnostics].inspect
    assert_equal l.projection.plan,decoded[:value].projection.plan
    assert_equal l.document,read[:value].document
  end
  def test_resize_and_grain_edit_keep_part_ids_and_owned_root_identity
    l=accepted;mark_unrelated
    old_root=l.document['root_id'];old_acceptance=l.document['acceptance_id']
    state=resize;state['part_policies'][0]['grain']['substrate']='v'
    c=revision(l,state)[:value];r=apply(c)
    assert r[:ok],r[:diagnostics].inspect
    now=r[:value]
    assert_equal 8,now.projection.plan['source_revision']
    assert_equal old_root,now.document['root_id']
    refute_equal old_acceptance,now.document['acceptance_id']
    assert_equal l.projection.plan['parts'].map { |p| p['part_id'] },now.projection.plan['parts'].map { |p| p['part_id'] }
    assert_equal 'v',now.projection.state['part_policies'][0]['grain']['substrate']
    top=now.inspection.root_handle[:children].find { |n| n[:tag][:part_id]==uuid(1002) }[:children][0]
    assert_equal 782,top[:vertices].map { |v| v[0] }.max
    assert_equal 'preserve',@model.extras['probe_dictionary']['draft']
    assert_same @sentinel,@model.roots.find { |n| n[:tag].nil? }
  end
  def test_precommit_failures_abort_once_and_restore_all_source_tree_and_extra_data
    %i[first_solid before_remove after_remove write].each do |phase|
      l=accepted;mark_unrelated;before=capture;c=revision(l,resize)[:value]
      @port.faults={phase=>:raise};r=apply(c)
      assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
      assert_equal before,capture,phase.to_s
      assert_equal 0,@port.calls[:commit]
      assert_equal 1,@port.calls[:abort]
      assert_raises(JPImosPro::ProjectCore::Fault) { @context.authority.validate_candidate(c) }
      @port.faults={};@port.calls.clear
    end
  end
  def test_reentry_is_refused_and_post_begin_document_change_is_verified_abort
    c=candidate;nested=nil
    @port.callbacks[:first_solid]=-> { nested=apply(c) }
    r=apply(c);assert r[:ok],r[:diagnostics].inspect
    assert_failure(nested,'E_HOST_REENTRANT','unchanged')
    l=r[:value];next_c=revision(l,resize)[:value];before=capture
    @port.callbacks={begin:-> { @model.document='changed during begin' }}
    r=apply(next_c)
    assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
    assert_equal before,capture
    assert_equal 1,@port.calls[:abort]
    assert_failure(apply(next_c),'E_HOST_LEASE_CONFLICT','unchanged')
  end
  def test_commit_uncertainty_never_aborts_or_automatically_repairs
    %i[false raise].each do |fault|
      c=candidate;@port.faults={commit:fault}
      r=apply(c)
      assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
      assert @context.authority.quarantined?
      assert_equal 0,@port.calls[:abort]
      refute_nil @model.document
      @port.faults={};@port.calls.clear
      readonly=read[:value];assert readonly.read_only?
      assert_failure(revision(readonly,resize),'E_HOST_RECOVERY_REQUIRED','unchanged')
      @port.settle(@context)
      recovered=JPImosPro::Host::Recovery.read(context:@context,fresh_grant:@port.controlled_grant,numeric_policy:policy)
      assert recovered[:ok],recovered[:diagnostics].inspect
      # Start another initial scenario only through an explicit new incarnation.
      JPImosPro::Host::Registry.close(anchor:@anchor)
      @model=HostTreeModel.new;@anchor=JPImosPro::Host::Registry.open(model:@model)
      @port=HostTreePort.new(@model,@anchor);@context=JPImosPro::Host::Registry.attach(port:@port)
    end
  end
  def test_abort_failure_is_unknown_and_quarantined
    c=candidate;@port.faults={first_solid: :raise,abort: :false}
    r=apply(c);assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 1,@port.calls[:abort];assert @context.authority.quarantined?
  end
  def test_post_commit_mutation_is_unknown_without_abort
    c=candidate
    @port.callbacks[:commit]=-> { @model.document=@model.document+' ';@context.authority.notify_external! }
    r=apply(c);assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 0,@port.calls[:abort]
    assert @context.authority.quarantined?
  end
  def test_nonempty_empty_nonempty_uses_no_empty_group_and_a_new_root
    first=apply[:value];refute_nil first;root=first.document['root_id']
    empty=physical_state;empty['design']['project']['articles']=[];empty['design']['construction_requests']=[];empty['part_policies']=[]
    c=revision(first,empty)[:value];r=apply(c);assert r[:ok],r[:diagnostics].inspect
    assert_empty @model.roots
    assert_nil r[:value].document['root_id']
    assert_equal 8,r[:value].projection.plan['source_revision']
    restored=physical_state;restored['design']['project']['revision']=8
    c=revision(r[:value],restored,8)[:value];refute_nil c
    r=apply(c);assert r[:ok],r[:diagnostics].inspect
    refute_equal root,r[:value].document['root_id']
    assert_equal 9,r[:value].projection.plan['source_revision']
    assert_equal uuid(1),r[:value].document['project_id']
  end
  def test_exhausted_creation_budget_still_aborts_once_without_false_rollback_claim
    l=accepted;c=revision(l,resize)[:value];before=capture
    # Preflight consumes74 visits for four bare solids. Limit100 exhausts
    # during staging; abort restores data but no visits remain to verify it.
    r=apply(c,{entity_visits:100})
    assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 'E_RESOURCE_LIMIT',r[:diagnostics][0][:details]['cause_code']
    assert_equal 1,@port.calls[:abort];assert_equal before,capture
    assert @context.authority.quarantined?
  end
  def test_refusals_before_begin_leave_data_and_candidate_unconsumed
    c=candidate;before=capture
    assert_failure(apply(c,{work:1}),'E_RESOURCE_LIMIT','unchanged')
    assert_equal before,capture;assert_equal 0,@port.calls[:begin]
    @context.authority.validate_candidate(c)
    @port.edit_path=true
    assert_failure(apply(c),'E_HOST_EDIT_CONTEXT','unchanged')
    @port.edit_path=false
    assert apply(c)[:ok]
  end
  def test_begin_false_or_exception_has_one_abort_and_verified_restoration
    %i[false raise].each do |mode|
      c=candidate;before=capture;@port.faults={begin:mode}
      r=apply(c);assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
      assert_equal before,capture
      assert_equal 1,@port.calls[:abort];assert_equal 0,@port.calls[:commit]
      @port.calls.clear;@port.faults={}
    end
  end
  def test_cancellation_has_one_verified_abort_while_fatal_exception_is_reraised
    c=candidate;before=capture;@port.faults={first_solid: :interrupt}
    r=apply(c);assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
    assert_equal before,capture;assert_equal 1,@port.calls[:abort]
    @port.calls.clear;@port.faults={first_solid: :fatal};c=candidate
    assert_raises(SystemExit) { apply(c) }
    assert_equal before,capture;assert_equal 1,@port.calls[:abort]
    assert @context.authority.quarantined?
  end
  def test_foreign_child_inserted_after_staging_is_detected_before_old_root_removal
    l=accepted;old=l.inspection.root_handle;before=capture;c=revision(l,resize)[:value]
    @port.callbacks[:stage_done]=-> { old[:children] << @port.node(:foreign,nil) }
    r=apply(c);assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
    assert_equal 0,@port.calls[:before_remove]
    assert_equal before,capture;assert_equal 1,@port.calls[:abort]
  end
  def test_abort_true_without_restoration_proof_remains_unknown
    c=candidate;@port.faults={first_solid: :raise}
    @port.callbacks[:after_abort]=-> { @model.roots << @port.node(:root,{kind:'root',root_id:uuid(99),project_id:uuid(1)}) }
    r=apply(c);assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 1,@port.calls[:abort];assert @context.authority.quarantined?
    assert_equal 'E_HOST_OWNERSHIP_CONFLICT',r[:diagnostics][0][:details]['rollback_code']
  end
  def test_budget_exhausted_after_commit_never_triggers_abort
    l=accepted;c=revision(l,resize)[:value]
    r=apply(c,{entity_visits:400})
    assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 1,@port.calls[:commit];assert_equal 0,@port.calls[:abort]
    assert_equal 'E_RESOURCE_LIMIT',r[:diagnostics][0][:details]['cause_code']
    assert @context.authority.quarantined?
  end
  def test_post_commit_geometry_change_without_notification_is_caught_by_inspection
    c=candidate
    @port.callbacks[:commit]=-> { @model.roots[0][:children][0][:children][0][:vertices][0][0]+=1 }
    r=apply(c);assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 0,@port.calls[:abort];assert @context.authority.quarantined?
  end
  def test_context_clone_other_model_and_changed_source_refused_before_begin
    c=candidate;before=capture
    assert_failure(apply(c,{},@context.dup),'E_HOST_CONTEXT_UNSUPPORTED','unchanged')
    model2=HostTreeModel.new;anchor2=JPImosPro::Host::Registry.open(model:model2)
    context2=JPImosPro::Host::Registry.attach(port:HostTreePort.new(model2,anchor2))
    begin
      context2.port.settle(context2)
      assert_failure(apply(c,{},context2),'E_HOST_LEASE_CONFLICT','unchanged')
    ensure
      JPImosPro::Host::Registry.close(anchor:anchor2)
    end
    assert_equal before,capture;assert_equal 0,@port.calls[:begin]
    @model.document='external replacement'
    assert_failure(apply(c),'E_HOST_LEASE_CONFLICT','unchanged')
    assert_equal 'external replacement',@model.document
    assert_equal 0,@port.calls[:begin]
  end
  def test_identity_generation_failure_before_begin_is_unchanged
    c=candidate;before=capture
    r=SecureRandom.stub(:uuid,-> { raise RuntimeError,'synthetic entropy failure' }) { apply(c) }
    assert_failure(r,'E_HOST_CONTEXT_UNSUPPORTED','unchanged')
    assert_equal before,capture;assert_equal 0,@port.calls[:begin]
  end
  def test_identity_failure_after_commit_does_not_prevent_quarantine
    c=candidate;i=0
    r=SecureRandom.stub(:uuid,-> { i+=1;raise RuntimeError,'synthetic entropy failure' if i>=3;uuid(4000+i) }) { apply(c) }
    assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 1,@port.calls[:commit];assert_equal 0,@port.calls[:abort]
    assert @context.authority.quarantined?
  end
  def test_original_typed_cause_keeps_semantic_part_reference_and_details
    c=candidate
    cause=JPImosPro::ProjectCore::Fault.new('E_HOST_GEOMETRY_CONFLICT','/host/parts/'+uuid(1000),{'part_id'=>uuid(1000)},{'reason'=>'synthetic mismatch'})
    @port.callbacks[:first_solid]=-> { raise cause }
    r=apply(c);assert_failure(r,'E_HOST_APPLY_FAILED','rolled_back')
    assert_equal cause.diagnostic,r[:diagnostics][0][:details]['cause']
  end
  def test_abort_exception_does_not_retry_or_claim_rollback
    c=candidate;@port.faults={first_solid: :raise,abort: :raise}
    r=apply(c);assert_failure(r,'E_HOST_COMMIT_INDETERMINATE','unknown')
    assert_equal 1,@port.calls[:abort];assert @context.authority.quarantined?
  end
end
