# frozen_string_literal: true


module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
end

require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/normalize"

