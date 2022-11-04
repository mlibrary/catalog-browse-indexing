# frozen_string_literal: true

require "authority_browse/connection"

module AuthorityBrowse
  module Author
    # We need a way to link up our authorities (as taking from the catalog) with
    # canonical LoC entries. The best (?) way to do this would be to have a well-developed
    # set of transformations (diacritics, lowercase, space collapsing, whatever)
    # that we could use to determine "exactish" matches.
    #
    # Doing matching against a database (the right way) would involve figuring out
    # how to use the icu library under ruby/jruby and figuring out how to apply
    # the entire list of transformations we want, and _then_ making sure the
    # script and the solr fieldType definition remained in sync
    #
    # The full list of transformations being done in lucene (which presumably was picked by smart
    # people) at https://lucene.apache.org/core/8_3_0/analyzers-icu/org/apache/lucene/analysis/icu/ICUFoldingFilter.html
    #   *  Accent removal
    #   *  Case folding
    #   *  Canonical duplicates folding
    #   *  Dashes folding
    #   *  Diacritic removal (including stroke, hook, descender)
    #   *  Greek letterforms folding
    #   *  Han Radical folding
    #   *  Hebrew Alternates folding
    #   *  Jamo folding
    #   *  Letterforms folding
    #   *  Math symbol folding
    #   *  Multigraph Expansions: All
    #   *  Native digit folding
    #   *  No-break folding
    #   *  Overline folding
    #   *  Positional forms folding
    #   *  Small forms folding
    #   *  Space folding
    #   *  Spacing Accents folding
    #   *  Subscript folding
    #   *  Superscript folding
    #   *  Suzhou Numeral folding
    #   *  Symbol folding
    #   *  Underline folding
    #   *  Vertical forms folding
    #   *  Width folding
    # ...plus NKFC normalization
    #
    # Looking at the lucene source code it's certainly doable, but reading the icu docs makes me
    # cross-eyed.
    #
    # The slow but easy way to do it is to let solr the heavy lifting
    class NAFMatcher
      attr_accessor :url, :field, :connection

      # @param [String] url The URL to the solr core that has the data to try to match against
      # @param [String] field The field in that solr core to try to match with
      def initialize(url:, field:)
        @url = url.chomp("/") + "/select"
        @field = field
        @connection = AuthorityBrowse::Connection.new
      end

      ESCAPE_CHARS = '+-&|!(){}[]^"~*?:\\'
      ESCAPE_MAP = ESCAPE_CHARS.chars.each_with_object({}) { |x, h| h[x] = "\\" + x }
      ESCAPE_PAT = Regexp.new("[" + Regexp.quote(ESCAPE_CHARS) + "]")

      def lucene_escape(str)
        str.to_s.gsub(ESCAPE_PAT, ESCAPE_MAP)
      end

      def params(term)
        {
          rows: 1,
          q: "*:*",
          fq: %(#{@field}:"#{lucene_escape(term)}"),
          wt: "json"
        }
      end

      # @param [String] str The string to try to match
      # @return [Hash, Nil] Either the first match, or nil if not found
      def find_naf(str)
        resp = connection.get(@url, params: params(str))
        solr_resp = resp.json
        if solr_resp.dig("response", "numFound") == 0
          nil
        else
          solr_resp.dig("response", "docs").first
        end
      end
    end
  end
end
