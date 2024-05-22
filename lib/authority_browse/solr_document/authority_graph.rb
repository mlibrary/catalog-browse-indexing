module AuthorityBrowse
  class SolrDocument
    class AuthorityGraph < Base
      TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
      EMPTY = [[], nil, "", {}, [nil], [false]]

      # Returns the first element of the Array. This contains most of the
      # information about the entry.
      #
      # @return [Hash]
      def first
        @data.first
      end

      # Is the count for the entry or any of the cross references greater than 0?
      #
      # @return [Boolean]
      def any?
        count > 0 || @data.any? do |x|
          !x[:xref_count].nil? && x[:xref_count] > 0
        end
      end

      # @return [String]
      def match_text
        first[:match_text]
      end

      # @return [String]
      def term
        first[:label]
      end

      # Library of Congress ID if the id is a valid one
      #
      # @return [String]
      def loc_id
        first[:id] if first[:id].match?("loc.gov")
      end

      # @return [Integer]
      def count
        first[:count]
      end

      # Hash of xref types. Each type has an array of the corresponding xrefs
      # and their count. Xrefs with 0 records are excluded for names and
      # included for subjects. Xrefs are sorted alphabetically
      #
      # @return [Hash]
      def xrefs
        @xrefs.map do |xref|
          [
            xref, @data.filter_map do |x|
              xref_count = x[:xref_count].to_i
              output = "#{x[:xref_label]}||#{xref_count}"
              if @kind.to_s == "name"
                output unless xref_count == 0
              elsif x[:xref_kind] == xref.to_s
                output
              end
            end.sort
          ]
        end.to_h
      end
    end
  end
end
