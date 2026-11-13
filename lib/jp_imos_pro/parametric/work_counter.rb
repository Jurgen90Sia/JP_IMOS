# frozen_string_literal: true
module JPImosPro
  module Parametric
    class WorkCounter
      attr_reader :used
      def initialize(limit:)
        unless limit.instance_of?(Integer) && limit.between?(1,100_000)
          raise Fault.new('E_INPUT_CONTRACT',nil,'counter.limit')
        end
        @limit,@used=limit,0
      end
      def tick(count=1)
        raise Fault.new('E_INPUT_CONTRACT') unless count.instance_of?(Integer) && count>=0
        @used += count
        raise Fault.new('E_RESOURCE_LIMIT') if @used>@limit
      end
    end
  end
end
