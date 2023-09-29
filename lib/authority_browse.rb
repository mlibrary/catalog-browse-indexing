# frozen_string_literal: true

require_relative "solr/term_fetcher"
require "milemarker"
require "logger"
require "byebug"

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")

  def self.load_terms_db
    milemarker = Milemarker.new(batch_size: 100_000, name: "Add terms to term_db", logger: Logger.new($stdout))
    milemarker.log "Start loading terms db"
    AuthorityBrowse.setup_terms_db
    term_fetcher = Solr::TermFetcher.new(field: "author_authoritative_browse")
    term_fetcher.each do |term, count|
      AuthorityBrowse.terms_db[:names].insert(term: term, count: count)
      milemarker.increment_and_log_batch_line
    end
    milemarker.log_final_line
  end
end

require "authority_browse/loc_authorities"
require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/normalize"
require "authority_browse/loc_skos/unmatched_entry"
require "authority_browse/models"
require "authority_browse/solr_document"
