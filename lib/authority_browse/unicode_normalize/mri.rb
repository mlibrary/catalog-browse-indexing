# frozen_string_literal: true

require "ffi-icu"

module AuthorityBrowse
  module Normalize
    module MRI
      NORMALIZER = ICU::Normalizer.new(nil, "nfc", :compose)
      ASCIIFY = ICU::Transliteration::Transliterator.new("Any-ASCII")
      LOWER = ICU::Transliteration::Transliterator.new("Any-Lower")

      # Takes a string and normalizes it.
      #
      # @param str [String] term to be normalized
      # @return [String] normalized string
      def unicode_normalize(str)
        LOWER.transliterate(ASCIIFY.transliterate(NORMALIZER.normalize(str)))
      end
    end
  end
end
