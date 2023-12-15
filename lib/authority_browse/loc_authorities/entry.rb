module AuthorityBrowse
  module LocAuthorities
    class Entry
      # Turns a hash of a skos line into something that can be put into the
      # database
      # @param data [Hash] [Hash version of a line of a skos file]
      def initialize(data)
        @data = data
      end

      # @return [String] Skos Entry Id
      def id
        @id ||= "http://id.loc.gov#{@data["@id"]}"
      end

      # @return [Hash] component from "@graph" that describes the main id
      def main_component
        @main_component ||= @data["@graph"].find { |x| x["@id"] == id }
      end

      # @return [String] Preferred Label
      def label
        raise NotImplementedError
      end

      # @return [String] Normalized version of the preferred label
      def match_text
        AuthorityBrowse::Normalize.match_text(label)
      end

      # @return [Boolean] Do any of the graph elements show that this id has been deprecated?
      def deprecated?
        @data["@graph"].any? { |x| x["cs:changeReason"] == "deprecated" }
      end

      def _get_xref_ids(key)
        xrefs = main_component[key]
        return [] if xrefs.nil?
        if xrefs.instance_of?(Hash)
          [xrefs["@id"]]
        else # it's an Array
          xrefs.map { |x| x["@id"] }
        end
      end
    end
  end
end
