# frozen_string_literal: true

require_relative "../../../vendor/icu4j-71.1.jar"
require "java"

module AuthorityBrowse
  module UnicodeNormalize
    module JRuby
      NORMALIZER = com.ibm.icu.text::Normalizer2.getNFKCCasefoldInstance
      TRANSLITERATOR = com.ibm.icu.text::Transliterator.getInstance("Any-ASCII")

      def normalize(str)
        TRANSLITERATOR.transliterate(NORMALIZER.normalize(str))
      end
    end
  end
end
