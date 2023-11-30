module AuthorityBrowse
  module LocAuthorities
    class Subject < Entry
      def label
        main_component&.dig("skos:prefLabel", "@value") || main_component&.dig("skosxl:literalForm", "@value")
      end

      def broader_ids
        @broader_ids ||= _get_xref_ids("skos:broader")
      end

      def narrower_ids
        @narrower_ids ||= _get_xref_ids("skos:narrower")
      end

      def xref_ids?
        !(narrower_ids.empty? && broader_ids.empty?)
      end
    end
  end
end
