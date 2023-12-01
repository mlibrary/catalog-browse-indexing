module AuthorityBrowse
  class SolrDocument
    class AuthorityGraph < Base
      TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
      EMPTY = [[], nil, "", {}, [nil], [false]]
      # @param data [Array] Array of hashes of name and one see_also
      # @parameter kind [symbol] :subject or :name
      # @paramter xrefs [Array]<Symbol> what xrefs are associated with the kind of date
      def initialize(data:, kind:)
        @data = data
        @kind = kind
      end

      def first
        @data.first
      end

      def any?
        count > 0 || @data.any? do |x|
          @kind.xrefs.any? do |xref|
            !x[xref.count_key].nil? && x[xref.count_key] > 0
          end
        end
      end

      def match_text
        first[:match_text]
      end

      def term
        first[:label]
      end

      def loc_id
        first[:id]
      end

      def count
        first[:count]
      end

      def xrefs
        @kind.xrefs.map do |xref|
          [
            xref.name, @data.filter_map do |x|
              current_xref_count = x[xref.count_key]
              "#{x[xref.label_key]}||#{current_xref_count}" unless current_xref_count.nil? || current_xref_count == 0
            end
          ]
        end.to_h
      end

      def see_also
        @data.filter_map do |xref|
          sa_count = xref[:see_also_count]
          "#{xref[:see_also_label]}||#{xref[:see_also_count]}" unless sa_count.nil? || sa_count == 0
        end
      end
    end
  end
end
