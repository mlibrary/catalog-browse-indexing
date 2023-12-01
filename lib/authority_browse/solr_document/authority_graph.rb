module AuthorityBrowse
  class SolrDocument
    class AuthorityGraph < Base
      TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
      EMPTY = [[], nil, "", {}, [nil], [false]]

      def first
        @data.first
      end

      def any?
        count > 0 || @data.any? do |x|
          !x[:xref_count].nil? && x[:xref_count] > 0
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
        @xrefs.map do |xref|
          [
            xref, @data.filter_map do |x|
              xref_count = x[:xref_count]
              output = "#{x[:xref_label]}||#{xref_count}"
              if @kind.to_s == "name"
                output unless xref_count.nil? || xref_count == 0
              elsif x[:xref_kind] == xref.to_s
                output
              end
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
