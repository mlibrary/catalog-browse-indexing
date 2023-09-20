# frozen_string_literal: true

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
end

require "milemarker"
require "authority_browse/loc_authorities"
require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/normalize"
require "authority_browse/loc_skos/unmatched_entry"
require "authority_browse/models"

