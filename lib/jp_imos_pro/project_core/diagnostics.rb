# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    class Fault < StandardError
      attr_reader :code, :json_pointer, :entity_ref, :details, :engine
      def initialize(code, pointer = '', entity_ref = nil, details = {}, engine = nil)
        @code, @json_pointer, @entity_ref, @details = code, pointer, entity_ref, details
        @engine=engine
        super(code)
      end
      def diagnostic
        result={code: code, severity: 'error', json_pointer: json_pointer,
          entity_ref: entity_ref, message_key: code.downcase, details: details}
        if engine
          [:grammar_version,:source_span,:symbol_ids].each { |key| result[key]=engine[key] }
          result[:message_key]=engine[:message_key]
        end
        result
      end
    end
    def self.pointer(base, key)
      base + '/' + key.to_s.gsub('~','~0').gsub('/','~1')
    end
  end
end
