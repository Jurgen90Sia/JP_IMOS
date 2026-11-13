# frozen_string_literal: true
require 'json'
module JPImosPro
  module ProjectCore
    module Codec
      class PairObject
        attr_reader :pairs
        def initialize
          @pairs = []
        end
        def []=(key, value)
          @pairs << [key, value]
        end
      end
      module_function
      def parse(source, budget)
        unless source.instance_of?(String) && source.valid_encoding? &&
            [Encoding::UTF_8, Encoding::US_ASCII].include?(source.encoding)
          raise Fault.new('E_INPUT_CONTRACT')
        end
        budget.cap(source.bytesize, :json_bytes, '')
        raw = JSON.parse(source, object_class: PairObject, max_nesting: budget.limit(:json_depth),
          allow_nan: false, create_additions: false)
        holder, duplicates = [], []
        stack = [[raw, holder, 0, '']]
        until stack.empty?
          value, target, key, path = stack.pop
          budget.tick(path)
          case value
          when PairObject
            output, seen = {}, {}
            target[key] = output
            value.pairs.reverse_each do |name, child|
              p = ProjectCore.pointer(path,name)
              duplicates << p if seen.key?(name)
              seen[name] = true
              stack << [child, output, name, p]
            end
          when Array
            output = Array.new(value.size)
            target[key] = output
            (value.size-1).downto(0) { |i| stack << [value[i],output,i,ProjectCore.pointer(path,i)] }
          else
            target[key] = value
          end
        end
        raise Fault.new('E_DUPLICATE_JSON_KEY', duplicates.min) unless duplicates.empty?
        holder[0]
      rescue JSON::NestingError
        raise Fault.new('E_RESOURCE_LIMIT')
      rescue JSON::ParserError, EncodingError
        raise Fault.new('E_INPUT_CONTRACT')
      end
    end
  end
end
