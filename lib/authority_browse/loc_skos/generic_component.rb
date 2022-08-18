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

      attr_reader :id, :type, :raw_entry

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
        (scheme && scheme.start_with?(target_prefix)) or id.start_with?(target_prefix)
      end

      def concept?
        @type == "skos:Concept"
      end


      def dig(*args)
        @raw_entry.dig(*args)
      end

      def collect_ids(key)
        arrayify(@raw_entry[key]).map { |b| b["@id"] }
      end

      def collect_single_id(key)
        @raw_entry.dig(key, "@id")
      end

      def collect_values(key)
        arrayify(@raw_entry[key]).map { |b| b["@value"] }
      end

      def collect_single_value(key)
        @raw_entry.dig(key, "@value")
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
