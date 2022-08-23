# frozen_string_literal: true

require_relative "loc_skos/subject"
require_relative "loc_skos/name"

module AuthorityBrowse
  # For round-tripping JSON <-> ruby objects
  JSON_CREATE_ID = JSON.create_id.freeze

  # We need something to join two strings such that they're only alphabetized by the
  # first component. SPACE and BANG are the first two printable characters on the ASCII
  # table so we'll use those.
  #
  # Note that we don't want to use just space, 'cause it's confusing, and we can't just use
  # '!' because "a b" sorts before "a!".
  #
  # Unicode (and ASCII) "1F" is designed for this sort of thing, but has the distinct
  # disadvantage of being invisible. We'll use it anyway until it seems like it's a
  # bad idea.
  ALPHABETIC_JOINER = "\u001F"

  def self.alphajoin(*strings)
    strings.map(&:strip).join(ALPHABETIC_JOINER)
  end

  def self.alphasplit(joined_string)
    joined_string.split(ALPHABETIC_JOINER)
  end

  module LocSKOSRDF
  end
end
