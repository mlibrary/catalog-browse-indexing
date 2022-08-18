# frozen_string_literal: true

require_relative "loc_skos/subject"

module AuthorityBrowse
  # For round-tripping JSON <-> ruby objects
  JSON_CREATE_ID = JSON.create_id.freeze

  # We need something to join two strings such that they're only alphabetized by the
  # first component. SPACE and BANG are the first two printable characters on the ASCII
  # table so we'll use those.
  #
  # Note that we don't want to use just space, 'cause it's confusing, and we can't just use
  # '!' because "a b" sorts before "a!".
  # The triple-bang is unusual enough that we'll risk using it.
  #
  # It would be better to use something designed for this (e.g., 1F) but it's just harder using
  # invisible separators. We can always change if we want to.
  ALPHABETIC_JOINER = " !!! "

  def self.alphajoin(*strings)
    strings.map(&:strip).join(ALPHABETIC_JOINER)
  end

  def self.alphasplit(joined_string)
    joined_string.split(ALPHABETIC_JOINER)
  end

  module LocSKOSRDF


  end