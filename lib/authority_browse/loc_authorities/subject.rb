module AuthorityBrowse
  module LocAuthorities
    class Subject < Entry
      # @return [String] Preferred Label
      def label
        main_component&.dig("skos:prefLabel", "@value") || main_component&.dig("skosxl:literalForm", "@value")
      end

      # @return [Array<String>] ids of broader xrefs
      def broader_ids
        @broader_ids ||= _get_xref_ids("skos:broader")
      end

      # @return [Array<String>] ids of narrower xrefs
      def narrower_ids
        @narrower_ids ||= _get_xref_ids("skos:narrower")
      end

      # @return [Boolean] Does it have any xref_ids?
      def xref_ids?
        !(narrower_ids.empty? && broader_ids.empty?)
      end
    end
  end
end
