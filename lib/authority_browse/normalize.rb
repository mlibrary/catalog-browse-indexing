# frozen_string_literal: true

module AuthorityBrowse
  module Normalize
    require "authority_browse/unicode_normalize/mri"
    extend MRI

    # Normalization for search will be as in out solr's browse_match fieldType
    #  * unicode downcase/latinize
    #  * cleanup spaces
    #  * remove unnecessary ending punctuation
    #  * remove spaces around "--" (for subjects)
    #
    # We might also want to experiment with:
    #  * Eliminate punctuation next to spaces
    #
    # We want it to match solr because we need to generate a search string that will find all the stuff
    # in the catalog we're claiming it should find.

    WHICH_PUNCT_TO_SPACIFY = /[:-]+/
    EMPTY_STRING = ""
    ONE_SPACE = " "
    # Return the appropriate match text for a given string
    #
    # @param str [String] String to be normalized
    # @return [String] Normalized string
    def match_text(str)
      str = unicode_normalize(str)
      str.gsub!(/\Athe\s+/, EMPTY_STRING)
      str.gsub!(/\s*--\s*/, "DOUBLEDASH")
      str = str.gsub(WHICH_PUNCT_TO_SPACIFY, ONE_SPACE)
      str = str.gsub(/\p{P}/, EMPTY_STRING)
      str = str.gsub("DOUBLEDASH", "--")
      cleanup_spaces(str)
    end

    # Gets rid of leading and trailing spaces. Shrinks other space to a single
    # space.
    #
    # @param str [String] String with spaces
    # @return [String] String with appropriate number of spaces
    def cleanup_spaces(str)
      str.gsub(/\s+/, ONE_SPACE).strip
    end

    extend self
  end
end
