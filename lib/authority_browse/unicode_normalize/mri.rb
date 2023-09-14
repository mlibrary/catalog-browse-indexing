# frozen_string_literal: true

require "ffi-icu"

module AuthorityBrowse
  module Normalize
    module MRI
      NORMALIZER = ICU::Normalizer.new(nil, 'nfc', :compose)
      ASCIIFY = ICU::Transliteration::Transliterator.new('Any-ASCII')
      LOWER = ICU::Transliteration::Transliterator.new('Any-Lower')

      def unicode_normalize(str)
        LOWER.transliterate(ASCIIFY.transliterate(NORMALIZER.normalize(str)))
      end
    end
  end
end
