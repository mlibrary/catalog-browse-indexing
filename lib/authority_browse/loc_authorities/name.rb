module AuthorityBrowse
  module LocAuthorities
    # This is a Skos Entry
    class Name < Entry
      # @return [String] Preferred Label
      def label
        main_component["skos:prefLabel"] || main_component["skosxl:literalForm"]
      end

      # @return [Array] [Array of strings of see_also_ids]
      def see_also_ids
        @see_also_ids ||= _get_xref_ids("rdfs:seeAlso")
      end

      # Are there any seealso ids?
      # @return [Boolean]
      def see_also_ids?
        !see_also_ids.empty?
      end
    end
  end
end
