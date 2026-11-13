# frozen_string_literal: true
require_relative 'construction'
require_relative 'design/record'
module JPImosPro
  module Design
    SCHEMA='jpimos.carcass-design/1'
    PROFILE='jp-carcass-design-v1'
    module_function
    def boundary(limits)
      result=ProjectCore.boundary(limits) { |budget| yield budget }
      result[:metadata]={schema:SCHEMA,profile_version:PROFILE}
      result
    end
    def validate(state:,limits: {})
      boundary(limits) { |budget| Record.validate(state,budget) }
    end
    def encode(state:,limits: {})
      boundary(limits) { |budget| ProjectCore::Codec.encode(Record.validate(state,budget),budget) }
    end
    def decode(source:,limits: {})
      boundary(limits) { |budget| Record.validate(ProjectCore::Codec.parse(source,budget),budget) }
    end
  end
end
