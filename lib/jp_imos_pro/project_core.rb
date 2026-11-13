# frozen_string_literal: true
require_relative 'project_core/diagnostics'
require_relative 'project_core/budget'
require_relative 'project_core/codec'
require_relative 'parametric'
require_relative 'project_core/quantities'
require_relative 'project_core/document'
require_relative 'project_core/parameters'
require_relative 'project_core/references'
require_relative 'zones/frame'
require_relative 'zones/engine_bridge'
require_relative 'zones/resolver'

module JPImosPro
  module ProjectCore
    SCHEMA = 'jpimos.project-core/1'
    PROFILE_VERSION = 'jp-project-contract-v1'
    module_function
    def boundary(limits)
      budget = CoreBudget.new(limits)
      value = yield budget
      {ok: true, value: value, diagnostics: [], metadata: {schema: SCHEMA, profile_version: PROFILE_VERSION}}
    rescue Fault => e
      {ok: false, value: nil, diagnostics: [e.diagnostic], metadata: {schema: SCHEMA, profile_version: PROFILE_VERSION}}
    end
    def decode_document(source:, limits: {})
      boundary(limits) { |budget| Document.validate(Codec.parse(source,budget),budget) }
    end
    def encode_document(document:, limits: {})
      boundary(limits) do |budget|
        validated = Document.validate(document,budget)
        Codec.encode(validated,budget)
      end
    end
    def resolve_zones(document:, numeric_policy:, limits: {})
      policy=nil
      result=boundary(limits) do |budget|
        validated=Document.validate(document,budget)
        begin
          Parametric.require_policy(numeric_policy)
        rescue Parametric::Fault
          raise Fault.new('E_INPUT_CONTRACT','/numeric_policy')
        end
        policy={policy_id:numeric_policy[:policy_id].dup,backend_id:numeric_policy[:backend_id].dup}
        Zones::Resolver.resolve(validated_document:validated,policy:policy,budget:budget)
      end
      if policy
        result[:metadata]=result[:metadata].merge(policy).merge(algorithm_version:Zones::Resolver::ALGORITHM)
      end
      result
    end
  end
end
