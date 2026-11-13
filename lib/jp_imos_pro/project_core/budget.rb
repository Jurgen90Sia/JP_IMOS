# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    class CoreBudget
      DEFAULTS = {json_bytes: 1_048_576, json_depth: 64, definitions: 100,
        articles: 100, zones: 1000, occurrences: 10_000, zone_depth: 32,
        parameters: 256, label_chars: 256, work: 100_000}.freeze
      def initialize(limits)
        raise Fault.new('E_INPUT_CONTRACT', '/limits') unless limits.instance_of?(Hash)
        limits.each do |key, value|
          unless DEFAULTS.key?(key) && value.instance_of?(Integer) && value > 0 && value <= DEFAULTS[key]
            raise Fault.new('E_INPUT_CONTRACT', '/limits')
          end
        end
        @limits, @work, @text_bytes = DEFAULTS.merge(limits), 0, 0
      end
      def limit(key)
        @limits.fetch(key)
      end
      def tick(pointer = '', count = 1)
        @work += count
        raise Fault.new('E_RESOURCE_LIMIT', pointer) if @work > limit(:work)
      end
      def cap(size, key, pointer)
        raise Fault.new('E_RESOURCE_LIMIT', pointer) if size > limit(key)
      end
      def text_bytes(count, pointer)
        @text_bytes += count
        cap(@text_bytes,:json_bytes,pointer)
      end
    end
  end
end
