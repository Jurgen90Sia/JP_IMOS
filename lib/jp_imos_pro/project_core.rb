# frozen_string_literal: true
require_relative 'project_core/diagnostics'
require_relative 'project_core/budget'
require_relative 'project_core/codec'
require_relative 'parametric'
require_relative 'project_core/quantities'
require_relative 'project_core/document'
require_relative 'project_core/parameters'
require_relative 'project_core/references'

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
  end
end
