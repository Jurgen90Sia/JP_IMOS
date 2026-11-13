# frozen_string_literal: true
module JPImosPro
  module ProjectCore
    class Fault < StandardError
      attr_reader :code, :json_pointer, :entity_ref, :details
      def initialize(code, pointer = '', entity_ref = nil, details = {})
        @code, @json_pointer, @entity_ref, @details = code, pointer, entity_ref, details
        super(code)
      end
      def diagnostic
        {code: code, severity: 'error', json_pointer: json_pointer,
          entity_ref: entity_ref, message_key: code.downcase, details: details}
      end
    end
    def self.pointer(base, key)
      base + '/' + key.to_s.gsub('~','~0').gsub('/','~1')
    end
  end
end
