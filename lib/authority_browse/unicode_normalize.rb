# frozen_string_literal: true

module AuthorityBrowse
  module UnicodeNormalize

    if IS_JRUBY
      require "authority_browse/unicode_normalize/jruby"
      extend JRuby
    else
      require "authority_browse/unicode_normalize/mri"
      extend MRI
    end

    def cleanup_spaces(str)
      str.gsub(/\s+/, " ").strip
    end

    def strip_leading_parens_year(str)
      str.gsub(/\A\(\d{4}\),?\s*/, '')
    end

    def spacify_some_punctuation(str)
      str.gsub(/[,."?]/, ' ').gsub(/'\s+/, "' ")
    end

    def normalize_more_aggressively(str)
      cleanup_spaces(
        normalize(
          spacify_some_punctuation(
            strip_leading_parens_year(str))))
    end

    extend self

  end
end



