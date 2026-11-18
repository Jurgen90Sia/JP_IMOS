# frozen_string_literal: true
require_relative 'native_geometry'
require_relative 'recovery'
module JPImosPro
  module Host
    class ScratchReservation
      include Opaque
      attr_reader :path
      def initialize(path);@path=path.freeze;freeze;end
      private_class_method :new
    end
    class ControlledContext
      include Opaque
      attr_reader :model,:path,:anchor
      def initialize(model,path,anchor);@model,@path,@anchor=model,path,anchor;freeze;end
      private_class_method :new
    end
    module Registry
      @native_contexts={}.compare_by_identity
      def self.issue_native_context(model,path,anchor)
        value=ControlledContext.send(:new,model,path,anchor)
        @native_contexts[value]=true;value
      end
      def self.native_context?(value);@native_contexts.key?(value);end
      def self.revoke_native_context(value);@native_contexts.delete(value);end
    end
    module NativeHarness
      @reservations={}.compare_by_identity
      @ports={}.compare_by_identity
      @tracked={}.compare_by_identity
      @lifecycle_observers={}.compare_by_identity
      module_function
      def fail!;raise ProjectCore::Fault.new('E_HOST_QUIESCENCE_UNPROVEN','/host/native_context');end
      def sdk!
        fail! unless Thread.current.equal?(Thread.main) && defined?(Sketchup::Model) && defined?(Geom::Point3d) && (21..26).include?(Sketchup.version.to_i)
      end
      def canonical(path)
        value=File.realpath(path).tr('\\','/')
        File::ALT_SEPARATOR ? value.downcase : value
      end
      # Caller selects an existing workspace output directory. No model/file
      # is saved here. Only this newly reserved exact path may be registered.
      def reserve_scratch(directory:)
        root=canonical(directory);fail! unless File.directory?(root)
        path=File.join(root,'jpimos-host-'+Registry.nonce+'.skp').tr('\\','/')
        fail! if File.exist?(path)
        reservation=ScratchReservation.send(:new,path)
        @reservations[reservation]=true;reservation
      rescue SystemCallError,TypeError
        fail!
      end
      def register(reservation:,model:,idle_asserted:)
        sdk!
        fail! unless @reservations.key?(reservation) && idle_asserted==true && model.is_a?(Sketchup::Model) &&
          Sketchup.active_model.equal?(model) && File.file?(reservation.path) && canonical(model.path)==reservation.path &&
          model.active_path.nil?
        existing=@ports.values.find { |port| port.capability.path==reservation.path }
        if existing
          fail! unless existing.capability.model.equal?(model)
          return Registry.attach(port:existing)
        end
        fail! if @ports.values.any? { |port| port.capability.model.equal?(model) }
        fail! if model.modified?
        anchor=Registry.open(model:model)
        capability=Registry.issue_native_context(model,reservation.path,anchor)
        port=NativePort.send(:new,capability)
        @ports[capability]=port
        context=Registry.attach(port:port)
        begin
          track_model(model,anchor)
          port.install_observer
          install_app_observer
        rescue Exception
          begin
            port.remove_observer
          rescue StandardError
            nil
          ensure
            revoke(port)
          end
          raise
        end
        context
      rescue SystemCallError,TypeError
        fail!
      end
      def validate(capability)
        sdk!
        fail! unless Registry.native_context?(capability) && @ports.key?(capability) &&
          Sketchup.active_model.equal?(capability.model) && File.file?(capability.path) && canonical(capability.model.path)==capability.path
        Registry.authority(capability.anchor).check_live
        true
      rescue SystemCallError,TypeError
        fail!
      end
      def port(context)
        Registry.context_authority(context)
        value=context.port
        fail! unless value.instance_of?(NativePort) && @ports[value.capability].equal?(value)
        validate(value.capability);value
      end
      def settled(context:,idle_asserted:)
        value=port(context)
        fail! unless idle_asserted==true && !context.authority.busy? && value.idle? && !value.edit_path_open?
        value.accept_grant(Registry.issue_grant(context:context))
      end
      def dispatch(context:,action:)
        value=port(context)
        fail! unless %i[undo redo save switch open close].include?(action) && !context.authority.busy?
        context.authority.before_action!
        value.gateway=action
        begin
          yield
        ensure
          value.gateway=nil
        end
      end
      def revoke(value)
        capability=value.capability
        return unless Registry.native_context?(capability)
        Registry.revoke_native_context(capability);@ports.delete(capability)
        # Detaching a port is NOT a model-close event. Preserve the shared
        # authority/quarantine until an actual observed incarnation transition.
        Registry.authority(capability.anchor).quarantine!
      end
      def detach(context:)
        value=context.port
        return unless value.instance_of?(NativePort)
        value.remove_observer if Registry.native_context?(value.capability)
        revoke(value)
        if @tracked.empty? && @app_observer
          Sketchup.remove_observer(@app_observer);@app_observer=nil
        end
      end
      def track_model(model,anchor)
        if @tracked.key?(model)
          fail! unless @tracked[model].equal?(anchor)
          return
        end
        klass=Class.new(Sketchup::ModelObserver) do
          def onDeleteModel(model);NativeHarness.close_model(model);end
        end
        observer=klass.new
        fail! unless model.add_observer(observer)
        @tracked[model]=anchor
        @lifecycle_observers[model]=observer
      end
      def close_model(model)
        anchor=@tracked.delete(model)
        return unless anchor
        @lifecycle_observers.delete(model)
        @ports.values.dup.each do |value|
          next unless value.capability.model.equal?(model)
          Registry.revoke_native_context(value.capability);@ports.delete(value.capability)
        end
        Registry.close(anchor:anchor)
      end
      # Callbacks only revoke/invalidate process state; they never edit a model.
      def app_notice(event,model=nil)
        if event==:quit
          @tracked.keys.each { |value| close_model(value) }
        elsif %i[new open close].include?(event)
          close_model(model) if @tracked.key?(model)
          @ports.values.dup.each { |value| value.notice(:switch) } unless event==:close
        elsif event==:activate
          @ports.values.dup.each { |value| value.notice(:switch) }
        end
      end
      def install_app_observer
        return if @app_observer
        klass=Class.new(Sketchup::AppObserver) do
          def onNewModel(model);NativeHarness.app_notice(:new,model);end
          def onOpenModel(model);NativeHarness.app_notice(:open,model);end
          def onActivateModel(model);NativeHarness.app_notice(:activate,model);end
          def onQuit;NativeHarness.app_notice(:quit);end
        end
        @app_observer=klass.new
        begin
          fail! unless Sketchup.add_observer(@app_observer)
        rescue Exception
          begin
            Sketchup.remove_observer(@app_observer)
          rescue StandardError
            nil
          ensure
            @app_observer=nil
          end
          raise
        end
      end
    end
    class NativePort
      DICTIONARY=NativeGeometry::DICTIONARY
      attr_reader :anchor,:capability,:numeric_policy
      attr_accessor :gateway
      def initialize(capability)
        @capability=capability;@anchor=capability.anchor;@model=capability.model
        @numeric_policy={policy_id:Parametric::POLICY,backend_id:"#{RUBY_VERSION}-#{RUBY_PLATFORM}-Math".freeze}.freeze
        @phase=:idle;@events=[];@controlled_grant=nil
      end
      private_class_method :new
      def guard!;NativeHarness.validate(@capability);end
      def controlled_grant;guard!;@controlled_grant;end
      def accept_grant(value);@controlled_grant=value;end
      def idle?;@phase==:idle && @gateway.nil?;end
      def edit_path_open?;guard!;!@model.active_path.nil?;end
      def document_json
        guard!
        dictionary=@model.attribute_dictionary(DICTIONARY,false)
        return nil unless dictionary
        result=nil;count=0
        dictionary.each_pair do |key,value|
          count+=1;NativeGeometry.fail!('/host/document') unless count==1 && key=='accepted_document_json' && value.instance_of?(String)
          result=value
        end
        result
      end
      def inspect_empty(budget:)
        guard!;NativeGeometry.inspect(@model,nil,nil,nil,budget)
      end
      def inspect_projection(plan:,root_id:,manifest:,budget:,staging:nil)
        guard!;NativeGeometry.inspect(@model,plan,root_id,manifest,budget,staging)
      end
      def write_guard!(phase)
        guard!
        NativeHarness.fail! unless Registry.authority(@anchor).busy? && @controlled_grant && @phase==phase && !edit_path_open?
      end
      def begin_operation(name)
        write_guard!(:idle);@phase=:starting;@events=[]
        value=@model.start_operation(name,true)
        @phase=:open;value==true
      end
      def stage_projection(projection:,root_id:,budget:)
        write_guard!(:open)
        Reader.check_port_policy(self,{policy_id:projection.plan['policy_id'],backend_id:projection.plan['backend_id']})
        NativeGeometry.stage(@model,projection,root_id,budget)
      end
      def remove_root(handle)
        write_guard!(:open)
        NativeGeometry.fail! unless handle.is_a?(Sketchup::Group) && handle.valid? && !handle.locked?
        @model.entities.erase_entities(handle)
        !handle.valid?
      end
      def write_document(json)
        write_guard!(:open)
        @model.set_attribute(DICTIONARY,'accepted_document_json',json)
        @model.get_attribute(DICTIONARY,'accepted_document_json')==json
      end
      def commit_operation
        write_guard!(:open);@phase=:committing
        value=@model.commit_operation
        value==true && @events==[:start,:commit]
      ensure
        @phase=:idle
      end
      def abort_operation
        guard!;@phase=:aborting
        value=@model.abort_operation
        value==true && @events.last==:abort
      ensure
        @phase=:idle
      end
      def notice(event)
        return unless Registry.native_context?(@capability)
        if event==:close
          NativeHarness.close_model(@model)
        elsif event==:start && %i[starting open committing].include?(@phase) && @events.empty?
          @events << :start
        elsif event==:commit && @phase==:committing && @events==[:start]
          @events << :commit
        elsif event==:abort && @phase==:aborting && (@events.empty? || @events==[:start])
          @events << :abort
        elsif (@gateway==:save && %i[pre_save post_save].include?(event)) || @gateway==event
          nil # Gateway already invalidated synchronously before dispatch.
        else
          Registry.authority(@anchor).notify_external!
        end
        nil
      end
      def install_observer
        owner=self
        klass=Class.new(Sketchup::ModelObserver)
        {onTransactionStart: :start,onTransactionCommit: :commit,onTransactionAbort: :abort,onTransactionEmpty: :empty,
          onTransactionUndo: :undo,onTransactionRedo: :redo,onActivePathChanged: :edit_path,
          onPreSaveModel: :pre_save,onPostSaveModel: :post_save,onDeleteModel: :close}.each do |name,event|
          klass.send(:define_method,name) { |_model| owner.notice(event) }
        end
        @observer=klass.new
        NativeHarness.fail! unless @model.add_observer(@observer)
      end
      def remove_observer
        @model.remove_observer(@observer) if @observer
      end
    end
  end
end
