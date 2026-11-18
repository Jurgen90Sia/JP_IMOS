# Manual actual-host entry point only. Loading defines methods, never dispatches.
require_relative '../../lib/jp_imos_pro/host/native_port'
module JPImosPro
  module Host
    module NativeQualification
      module_function
      def initial(context:,state:,evidence_path:,idle_asserted:)
        NativeHarness.fail! if defined?(NativeSDKDouble)
        port=NativeHarness.port(context)
        NativeHarness.fail! unless NativeHarness.canonical(File.dirname(evidence_path))==File.dirname(port.capability.path)
        report=nil
        # Reserve evidence before dispatch; never overwrite existing evidence.
        File.open(evidence_path,File::WRONLY|File::CREAT|File::EXCL) do |file|
          NativeHarness.settled(context:context,idle_asserted:idle_asserted)
          policy=port.numeric_policy
          result=Reader.read(context:context,numeric_policy:policy)
          result=Preparation.initial(lease:result[:value],state:state,numeric_policy:policy) if result[:ok]
          result=Application.apply(context:context,candidate:result[:value]) if result[:ok]
          report={'schema'=>'jpimos.native-initial-evidence/1','sketchup_version'=>Sketchup.version,
            'ruby_version'=>RUBY_VERSION,'ruby_platform'=>RUBY_PLATFORM,'numeric_policy'=>policy,
            'ok'=>result[:ok],'diagnostics'=>result[:diagnostics],'metadata'=>result[:metadata],
            'scratch_path'=>port.capability.path,'disk_saved'=>false}
          if result[:ok]
            lease=result[:value]
            report['document_sha256']=lease.raw_sha256
            report['source_revision']=lease.projection.plan['source_revision']
            report['state_sha256']=lease.projection.plan['state_sha256']
            report['plan_sha256']=lease.projection.plan_sha256
            report['observed_manifest']=lease.inspection.manifest
          end
          file.write(JSON.pretty_generate(report))
        end
        report
      end
    end
  end
end
