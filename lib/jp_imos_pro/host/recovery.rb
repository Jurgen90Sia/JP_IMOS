# frozen_string_literal: true
require_relative 'reader'
module JPImosPro
  module Host
    module Recovery
      module_function
      def read(context:,fresh_grant:,numeric_policy:,limits: {})
        Registry.boundary(limits) do |budget,visits|
          authority=Registry.context_authority(context)
          authority.with_guard do
            Reader.inspect_with_budget(context,numeric_policy,budget,visits,true,fresh_grant)
          end
        end
      end
    end
  end
end
