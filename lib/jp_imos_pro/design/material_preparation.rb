# frozen_string_literal: true
require_relative '../materials/catalog'

module JPImosPro
  module Design
    module MaterialPreparation
      SCHEMA='jpimos.material-bound-design/1'
      PROFILE='jp-material-bound-design-v1'
      module_function

      # Prepares the current revision; no accepted/session/host state is written.
      def prepare(state:,catalog:,numeric_policy:,limits: {})
        policy=nil
        result=ProjectCore.boundary(limits) do |budget|
          owned=Record.validate(state,budget)
          index=Materials::Catalog.normalize(catalog,budget)
          registry,report=Materials::Catalog.resolve_owned(owned,index,budget)
          policy=ProjectCore.validated_policy(numeric_policy,budget)
          snapshot=Snapshot.build(owned,policy,budget)
          payload={'schema'=>SCHEMA.dup,'profile_version'=>PROFILE.dup,
            'state'=>owned,'catalog'=>registry,'snapshot'=>snapshot,'material_report'=>report}
          # Bounded plain-data copying also gives deterministic object-key order
          # for the package digest. Derived data is rebuilt, never imported.
          validator=ProjectCore::Document.new(budget)
          value=validator.copy(payload)
          value['content_sha256']=Digest::SHA256.hexdigest(ProjectCore::Codec.encode(value,budget))
          validator.deep_freeze(value)
        end
        result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
        result[:metadata]=result[:metadata].merge(policy) if policy
        result
      end
    end
  end
end
