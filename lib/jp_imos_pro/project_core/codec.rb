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
      def encode(document, budget)
        output = JSON.generate(document, max_nesting: budget.limit(:json_depth), allow_nan: false)
        budget.cap(output.bytesize,:json_bytes,'')
        output.force_encoding(Encoding::UTF_8)
      rescue JSON::NestingError
        raise Fault.new('E_RESOURCE_LIMIT')
      end
      def parse(source, budget)
        unless source.instance_of?(String) && source.valid_encoding? &&
            [Encoding::UTF_8, Encoding::US_ASCII].include?(source.encoding)
          raise Fault.new('E_INPUT_CONTRACT')
        end
        budget.cap(source.bytesize, :json_bytes, '')
        numeric_token_bound(source)
        raw = JSON.parse(source, object_class: PairObject, max_nesting: budget.limit(:json_depth),
          allow_nan: false, create_additions: false)
        holder, duplicates = [], []
        stack = [[raw, holder, 0, '']]
        until stack.empty?
          value, target, key, path = stack.pop
          budget.tick(path)
          case value
          when PairObject
            budget.tick(path,value.pairs.size)
            output, seen = {}, {}
            target[key] = output
            value.pairs.reverse_each do |name, child|
              p = ProjectCore.pointer(path,name)
              duplicates << p if seen.key?(name)
              seen[name] = true
              stack << [child, output, name, p]
            end
          when Array
            budget.tick(path,value.size)
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
      # All unquoted project numbers are bounded safe-integer fields. Ratio
      # numerators are quoted strings and must not be parsed as giant Integers.
      def numeric_token_bound(source)
        quoted, escaped, digits = false, false, 0
        source.each_char do |char|
          if quoted
            if escaped
              escaped=false
            elsif char=='\\'
              escaped=true
            elsif char=='"'
              quoted=false
            end
          elsif char=='"'
            quoted=true
            digits=0
          elsif char >= '0' && char <= '9'
            digits += 1
            raise Fault.new('E_INPUT_CONTRACT') if digits > 16
          else
            digits=0
          end
        end
      end
    end
  end
end
