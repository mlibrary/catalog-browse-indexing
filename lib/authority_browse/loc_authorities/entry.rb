module AuthorityBrowse
  module LocAuthorities
    # This is a Skos Entry
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

      # @return [String] Preferred Label
      def label
        main_component["skos:prefLabel"]
      end

      # @return [Array] [Array of strings of see_also_ids]
      def see_also_ids
        @see_also_ids ||= _get_see_also_ids
      end

      def _get_see_also_ids
        rdfs_see_also = main_component["rdfs:seeAlso"]
        return [] if rdfs_see_also.nil?
        if rdfs_see_also.instance_of?(Hash)
          [rdfs_see_also["@id"]]
        else # it's an Array
          rdfs_see_also.map { |x| x["@id"] }
        end
      end

      def main_component
        @main_component ||= @data["@graph"].find { |x| x["@id"] == id }
      end

      # Are there any seealso ids?
      # @return [Boolean]
      def see_also_ids?
        !see_also_ids.empty?
      end
    end
  end
end
