require 'minitest/autorun'
require 'minitest/mock'
require_relative '../design/fixtures'
require_relative '../../lib/jp_imos_pro/host/application'
require_relative 'native_support'
path=File.expand_path('../../lib/jp_imos_pro/host/native_port.rb',__dir__)
require path if File.exist?(path)
class NativePortTest < Minitest::Test
  include PhysicalDesignFixtures
  def setup
    return unless defined?(JPImosPro::Host::NativeHarness)
    @directory=Dir.mktmpdir('jpimos-native-double-')
    @model=Sketchup::Model.new;Sketchup.active_model=@model
    @reservation=JPImosPro::Host::NativeHarness.reserve_scratch(directory:@directory)
    @model.save(@reservation.path)
    @context=JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
  end
  def teardown
    NativeSDKDouble::Entities.face_limit=nil
    if @context
      @model.notify(:onDeleteModel)
      JPImosPro::Host::NativeHarness.detach(context:@context)
      raise 'unsafe temp cleanup' unless File.dirname(File.realpath(@directory))==File.realpath(Dir.tmpdir)
      FileUtils.remove_entry(@directory)
    end
  end
  def native_read
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy)
  end
  def candidate(state=physical_state)
    r=native_read;assert r[:ok],r[:diagnostics].inspect
    r=JPImosPro::Host::Preparation.initial(lease:r[:value],state:state,numeric_policy:policy)
    assert r[:ok],r[:diagnostics].inspect;r[:value]
  end
  def applied(state=physical_state)
    r=JPImosPro::Host::Application.apply(context:@context,candidate:candidate(state))
    assert r[:ok],r[:diagnostics].inspect;r[:value]
    assert_equal 'committed',r[:metadata][:mutation_state]
    r[:value]
  end
  def test_native_entry_point_exists_without_automatic_dispatch
    assert defined?(JPImosPro::Host::NativePort),'missing controlled native port'
  end
  def test_unregistered_reservation_model_path_edit_and_missing_idle_are_refused
    assert_raises(NoMethodError) { JPImosPro::Host::NativePort.new }
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeHarness.register(reservation:@reservation.dup,model:@model,idle_asserted:true)
    end
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:false)
    end
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    @model.active_path=[Object.new]
    error('E_HOST_EDIT_CONTEXT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
    @model.active_path=nil
    other=Sketchup::Model.new;Sketchup.active_model=other
    error('E_HOST_QUIESCENCE_UNPROVEN',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
    Sketchup.active_model=@model
    @model.save(File.join(@directory,'unregistered.skp'))
    error('E_HOST_QUIESCENCE_UNPROVEN',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
  end
  def test_complete_adapter_build_read_and_revision_on_sdk_double
    l=applied
    assert_equal 4,l.inspection.root_handle.entities.count
    assert_equal 1,@model.calls[:commit]
    state=physical_state;state['design']['project']['articles'][0]['parameter_values']['W']=length(800)
    r=JPImosPro::Host::Preparation.revision(lease:l,replacement:state,expected_revision:7,numeric_policy:policy)
    assert r[:ok],r[:diagnostics].inspect
    r=JPImosPro::Host::Application.apply(context:@context,candidate:r[:value])
    assert r[:ok],r[:diagnostics].inspect
    assert_equal 8,r[:value].projection.plan['source_revision']
    assert_equal l.document['root_id'],r[:value].document['root_id']
    assert_equal r[:value].document,native_read[:value].document
  end
  def test_locked_transformed_corrupt_face_extra_child_and_shared_definition_are_refused
    l=applied;root=l.inspection.root_handle;raw=@context.port.document_json
    root.locked=true;error('E_HOST_OWNERSHIP_CONFLICT',native_read);root.locked=false
    root.transformation.values[12]=1
    error('E_HOST_GEOMETRY_CONFLICT',native_read);root.transformation.values[12]=0
    solid=root.entities.first.entities.first
    face=solid.entities.find { |e| e.is_a?(Sketchup::Face) };face.reverse!
    failure=native_read;error('E_HOST_GEOMETRY_CONFLICT',failure)
    refute_nil failure[:diagnostics][0][:entity_ref]
    assert_equal uuid(1000),failure[:diagnostics][0][:entity_ref]['part_id']
    face.reverse!
    root.definition.instances_count=2
    error('E_HOST_OWNERSHIP_CONFLICT',native_read);root.definition.instances_count=1
    extra=root.entities.add_group
    error('E_HOST_OWNERSHIP_CONFLICT',native_read);root.entities.erase_entities(extra)
    assert_equal raw,@context.port.document_json
  end
  def test_global_orphan_cycles_and_cap_fail_without_eager_enumeration
    g=@model.entities.add_group
    g.set_attribute(JPImosPro::Host::NativePort::DICTIONARY,'binding_json','{"schema":"invalid"}')
    error('E_HOST_OWNERSHIP_CONFLICT',native_read)
    @model.entities.erase_entities(g)
    parent=@model.entities.add_group;parent.entities.items << Sketchup::ComponentInstance.new(parent.definition)
    error('E_HOST_OWNERSHIP_CONFLICT',native_read)
    @model.entities.erase_entities(parent)
    4.times { @model.entities.add_group }
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    error('E_RESOURCE_LIMIT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy,limits:{entity_visits:2}))
  end
  def test_expected_commit_events_pass_but_external_duplicate_and_save_events_quarantine
    applied
    @model.notify(:onTransactionCommit)
    assert @context.authority.quarantined?
    r=native_read;assert r[:ok];assert r[:value].read_only?
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    r=JPImosPro::Host::Recovery.read(context:@context,fresh_grant:@context.port.controlled_grant,numeric_policy:policy)
    assert r[:ok],r[:diagnostics].inspect
    old=r[:value]
    JPImosPro::Host::NativeHarness.dispatch(context:@context,action: :save) do
      @model.notify(:onPreSaveModel);@model.notify(:onPostSaveModel)
    end
    error('E_HOST_LEASE_CONFLICT',JPImosPro::Host::Preparation.revision(lease:old,replacement:physical_state,expected_revision:7,numeric_policy:policy))
    refute @context.authority.quarantined?
    @model.notify(:onPreSaveModel);assert @context.authority.quarantined?
  end
  def test_runtime_policy_mismatch_and_missing_grant_refuse_before_geometry
    error('E_HOST_QUIESCENCE_UNPROVEN',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    error('E_NUMERIC_POLICY_CONFLICT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:{policy_id:policy[:policy_id],backend_id:'wrong'}))
    assert_equal 0,@model.entities.count
  end
  def test_nil_stored_record_is_malformed_not_an_empty_unaccepted_model
    @model.set_attribute(JPImosPro::Host::NativePort::DICTIONARY,'accepted_document_json',nil)
    error('E_HOST_OWNERSHIP_CONFLICT',native_read)
    assert_equal 0,@model.calls[:begin]
  end
  def test_failed_observer_registration_cannot_be_reused_as_an_unwatched_context
    JPImosPro::Host::NativeHarness.detach(context:@context)
    @model.observer_failure=true
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    end
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    end
    @model.observer_failure=false
    @context=JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    assert_equal 2,@model.observers.size
  end
  def test_incremental_scan_stops_an_unbounded_sdk_iterator
    source=NativeSDKDouble::LazyEntities.new
    @model.instance_variable_set(:@entities,source)
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    error('E_RESOURCE_LIMIT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy,limits:{entity_visits:2}))
    assert_equal 3,source.yield_count
  end
  def test_close_reopen_rotates_incarnation_and_copied_capability_is_refused
    old=@context.authority.anchor
    @model.notify(:onDeleteModel)
    @context=JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    refute_same old,@context.authority.anchor
    assert_raises(JPImosPro::ProjectCore::Fault) { JPImosPro::Host::NativeHarness.validate(@context.port.capability.dup) }
  end
  def test_sdk_face_creation_failure_rolls_back_partial_groups_and_attributes
    c=candidate;NativeSDKDouble::Entities.face_limit=1
    r=JPImosPro::Host::Application.apply(context:@context,candidate:c)
    error('E_HOST_APPLY_FAILED',r)
    assert_equal 'rolled_back',r[:metadata][:mutation_state]
    assert_equal 1,@model.calls[:abort];assert_equal 0,@model.calls[:commit]
    assert_empty @model.entities.to_a
    assert_nil @context.port.document_json
  end
  def test_layers_translation_and_ground_face_orientation
    state=physical_state
    state['design']['project']['articles'][0]['origin']=[length(100),length(200),length(-18)]
    state['catalog']['entries'] << {'id'=>uuid(901),'version'=>1,'label'=>'Synthetic surface','category'=>'surface','provenance'=>{'kind'=>'user_declared','note'=>''}}
    state['design']['construction_requests'][0]['panels']['left']['dimensional_surfaces']=[surface('near',1,10),surface('far',1,5)]
    state['part_policies'][0]['grain']['surfaces']=%w[u none]
    l=applied(state)
    assert_equal [3,1,1,1],l.inspection.root_handle.entities.map { |p| p.entities.count }
    assert_equal l.document,native_read[:value].document
  end
  def test_app_observer_failure_cleanup_and_uncontrolled_open_revoke
    JPImosPro::Host::NativeHarness.detach(context:@context)
    @model.notify(:onDeleteModel)
    JPImosPro::Host::NativeHarness.detach(context:@context)
    Sketchup.stub(:add_observer,false) do
      2.times do
        assert_raises(JPImosPro::ProjectCore::Fault) do
          JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
        end
      end
    end
    assert_equal 1,@model.observers.size # Lifecycle watch remains through failed attachment.
    @context=JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    Sketchup.app_notice(:onOpenModel,@model)
    error('E_HOST_LEASE_CONFLICT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy))
  end
  def test_sketchup_2021_0_without_group_glued_to_uses_non_gluable_behavior_guard
    l=applied
    l.inspection.root_handle.singleton_class.send(:undef_method,:glued_to)
    result=native_read
    assert result[:ok],result[:diagnostics].inspect
  end
  def test_manual_qualification_cannot_label_sdk_double_results_as_actual_host_evidence
    require_relative 'native_qualification'
    evidence=File.join(@directory,'evidence.json')
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeQualification.initial(context:@context,state:physical_state,evidence_path:evidence,idle_asserted:true)
    end
    refute File.exist?(evidence)
    assert_equal 0,@model.calls[:begin]
  end
  def test_cycle_detection_uses_native_definition_identity_not_ruby_wrapper_identity
    parent=@model.entities.add_group
    instance=Sketchup::ComponentInstance.new(parent.definition)
    wrapper=Struct.new(:entityID,:entities)
    instance.define_singleton_method(:definition) { wrapper.new(parent.definition.entityID,parent.entities) }
    parent.entities.items << instance
    JPImosPro::Host::NativeHarness.settled(context:@context,idle_asserted:true)
    error('E_HOST_OWNERSHIP_CONFLICT',JPImosPro::Host::Reader.read(context:@context,numeric_policy:policy,limits:{entity_visits:10}))
  end
  def test_live_reservation_cannot_be_attached_to_another_model
    other=Sketchup::Model.new;other.save(@reservation.path);Sketchup.active_model=other
    assert_raises(JPImosPro::ProjectCore::Fault) do
      JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:other,idle_asserted:true)
    end
    Sketchup.active_model=@model
  end
  def test_detach_and_reattach_cannot_clear_shared_quarantine
    applied;@context.authority.quarantine!
    authority=@context.authority
    JPImosPro::Host::NativeHarness.detach(context:@context)
    @context=JPImosPro::Host::NativeHarness.register(reservation:@reservation,model:@model,idle_asserted:true)
    result=native_read;assert result[:ok],result[:diagnostics].inspect
    assert authority.equal?(@context.authority),'reattachment replaced model authority'
    assert result[:value].read_only?
  end
  def test_vertex_tolerance_is_per_axis_not_euclidean
    l=applied;solid=l.inspection.root_handle.entities.first.entities.first
    edges=solid.entities.select { |e| e.is_a?(Sketchup::Edge) }
    vertices=edges.flat_map { |e| [e.start,e.end] }.uniq { |v| v.entityID }
    vertices.each { |v| v.position=NativeSDKDouble::Point.new(v.position.to_a.map { |n| n+0.0009/25.4 }) }
    r=native_read;assert r[:ok],r[:diagnostics].inspect
    vertices.each do |v|
      p=v.position.to_a;p[0]+=0.0002/25.4;v.position=NativeSDKDouble::Point.new(p)
    end
    error('E_HOST_GEOMETRY_CONFLICT',native_read)
  end
end
