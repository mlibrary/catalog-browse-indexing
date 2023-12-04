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

    # PUNCT_SPACE_COMBO = /(?:\p{P}+(?:\s+|\Z))|(?:(?:\A|\s+)\p{P}+)/
    UNNECESSARY_ENDING_PUNCT = /[\/.;,]+\Z/

    # not sure this is used anywhere
    # For a sort key, we want to eliminate punctuation in general.
    # However, things that act like a space between words should
    # be turned into spaces.

    # This should match as exactly as possible the fieldType authority_search

    WHICH_PUNCT_TO_SPACIFY = /[:-]+/
    EMPTY_STRING = ""
    ONE_SPACE = " "
    # this is used
    def match_text(str)
      str = unicode_normalize(str)
      str.gsub!(/\Athe\s+/, EMPTY_STRING)
      str.gsub!(/\s*--\s*/, "DOUBLEDASH")
      str = str.gsub(WHICH_PUNCT_TO_SPACIFY, ONE_SPACE)
      str = str.gsub(/\p{P}/, EMPTY_STRING)
      str = str.gsub("DOUBLEDASH", "--")
      cleanup_spaces(str)
    end

    def cleanup_spaces(str)
      str.gsub(/\s+/, ONE_SPACE).strip
    end

    extend self
  end
end
