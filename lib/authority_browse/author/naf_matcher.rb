# frozen_string_literal: true

module AuthorityBrowse
  module Author

    # We need a way to link up our authorities (as taking from teh catalog) with
    # NAF entries. The best (?) way to do this would be to have a well-developed
    # set of transformations (diacritics, lowercase, space collapsing, whatever)
    # that we could use to determine "exactish" matches.
    #
    # This would involve figuring out how to use the ICU library (preferably under both
    # MRI and JRuby), which isn't a big deal but hasn't been done.
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
    # Looking at the lucene source code it's certainly doable, but reading the docs makes me
    # cross-eyed
    #
    # The cheap (but slow) and easy way to do it is to let solr the heavy lifting
    class NAFMatcher

      attr_accessor :url, :field

      # @param [String] url The URL to the solr core that has the data to try to match against
      # @param [String] field The field in that solr core to try to match with
      def initialize(url:, field:)
        @url = url
        @field = field
      end

      # @return [Faraday::Connection] A new connection
      def connection
        @connection ||= Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
          builder.use Faraday::Response::RaiseError
          builder.request :url_encoded
          # builder.request :retry
          builder.response :json
          builder.adapter :httpx
        end
      end

      ESCAPE_CHARS = '+-&|!(){}[]^"~*?:\\'
      ESCAPE_MAP = ESCAPE_CHARS.split(//).each_with_object({}) { |x, h| h[x] = "\\" + x }
      ESCAPE_PAT = Regexp.new('[' + Regexp.quote(ESCAPE_CHARS) + ']')

      def lucene_escape(str)
        str.to_s.gsub(ESCAPE_PAT, ESCAPE_MAP)
      end

      def params(name)
        {
          rows: 1,
          q: "*:*",
          fq: %Q[#{@field}:"#{lucene_escape(name)}"],
          wt: "json"
        }
      end

      # @param [String] The string to try to match
      # @return [Hash, Nil] Either the first match, or nil if not found
      def find_naf(str)
        resp = connection.get(@url + '/select', params(str))
        solr_resp = resp.body
        if solr_resp.dig("response", "numFound") == 0
          nil
        else
          solr_resp.dig("response", "docs").first
        end
      end

    end
  end
end