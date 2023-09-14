## frozen_string_literal: true

module AuthorityBrowse
  module LocSKOSRDF
    # A generic item that makes it easier to get at some of the interesting stuff
    # This is just syntactic sugar over the top of an entry in the `@graph` list
    # in a SKOS lines in the lcsh file
    class GenericComponent
      def self.target_prefix
        raise "Target prefix needs to be defined as a class method in subclasses"
      end

      attr_reader :type, :raw_entry
      attr_accessor :id

      # @param [Hash] item One of the graph entries for an LCSH line
      def initialize(item)
        @raw_entry = item
        @id = @raw_entry["@id"]
        @type = @raw_entry["@type"]
      end

      def target_prefix
        @tf ||= self.class.target_prefix
      end

      def scheme
        @scheme ||= @raw_entry.dig("skos:inScheme", "@id")
      end

      def in_target_prefix?
        scheme&.start_with?(target_prefix) or id.start_with?(target_prefix)
      end

      def concept?
        @type == "skos:Concept"
      end

      def dig(*)
        @raw_entry.dig(*)
      end

      def collect_ids(*)
        arrayify(dig(*)).map { |b| b["@id"].unicode_normalize(:nfkc) }
      end

      def collect_single_id(*)
        dig(*, "@id")&.unicode_normalize(:nfkc)
      end

      def collect_values(*)
        arrayify(dig(*)).map { |b| b["@value"].unicode_normalize(:nfkc) }
      end

      def collect_single_value(*)
        dig(*, "@value")&.unicode_normalize(:nfkc)
      end

      def collect_scalar(*)
        dig(*)&.unicode_normalize(:nfkc)
      end

      def collect_scalars(*)
        arrayify(dig(*)).map { |x| x.unicode_normalize(:nfkc) }
      end

      def arrayify(val)
        case val
        when Array
          val.compact
        when nil, false, true
          []
        else
          [val].compact
        end
      end
    end
  end
end
