# frozen_string_literal: true
require_relative 'registry'
module JPImosPro
  module Host
    class Inspection
      attr_reader :root_handle,:manifest
      def initialize(root_handle,manifest)
        @root_handle,@manifest=root_handle,manifest
        freeze
      end
      private_class_method :new
      # Trusted port supplies a borrowed result. Reader bounds, validates and
      # owns the plain mapping before publication; SDK handles remain opaque.
      def self.from_port(root_handle:,manifest:)
        new(root_handle,manifest)
      end
    end
    class Lease
      include Opaque
      attr_reader :authority,:context,:epoch,:sequence,:raw_document,:raw_sha256,:document,:projection,:inspection,:policy
      def initialize(authority,context,epoch,sequence,raw,document,projection,inspection,policy,read_only)
        @authority,@context,@epoch,@sequence=authority,context,epoch,sequence
        @raw_document=raw
        @raw_sha256=raw.nil? ? nil : Digest::SHA256.hexdigest(raw).freeze
        @document,@projection,@inspection,@policy=document,projection,inspection,policy
        @read_only=read_only
        freeze
      end
      def read_only?;@read_only;end
      private_class_method :new
    end
    class Candidate
      include Opaque
      attr_reader :authority,:base_lease,:projection,:policy
      def initialize(authority,lease,projection,policy)
        @authority,@base_lease,@projection,@policy=authority,lease,projection,policy
        freeze
      end
      def epoch;@base_lease.epoch;end
      def sequence;@base_lease.sequence;end
      private_class_method :new
    end
  end
end
