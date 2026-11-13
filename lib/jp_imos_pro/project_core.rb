# frozen_string_literal: true
require_relative 'project_core/diagnostics'
require_relative 'project_core/budget'
require_relative 'project_core/codec'

module JPImosPro
  module ProjectCore
    SCHEMA = 'jpimos.project-core/1'
    PROFILE_VERSION = 'jp-project-contract-v1'
  end
end
