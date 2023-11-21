# frozen_string_literal: true

require "milemarker"
require "logger"
require "byebug"
require "services"
require "concurrent"

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
end

require "authority_browse/loc_authorities"
require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/db_mutator"
require "authority_browse/term_fetcher"
require "authority_browse/normalize"
require "authority_browse/loc_skos/unmatched_entry"
require "authority_browse/solr"
require "authority_browse/solr_document"
require "authority_browse/names"
require "authority_browse/solr_uploader"
