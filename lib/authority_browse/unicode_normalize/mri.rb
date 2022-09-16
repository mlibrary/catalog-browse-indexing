# frozen_string_literal: true

require "icu"

module AuthorityBrowse
  module Normalize
    module MRI
      NORMALIZER = ICU::Normalizer.new(:nfc, :compose)
      ASCIIFY = ICU::Transliterator.new("Any-Ascii")
      LOWER = ICU::Transliterator.new("Lower")

      def unicode_normalize(str)
        LOWER.transliterate(ASCIIFY.transliterate(NORMALIZER.normalize(str)))
      end
    end
  end
end
