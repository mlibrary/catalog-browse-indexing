# frozen_string_literal: true

require_relative "solr/term_fetcher"

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
  def self.generate_and_send_solr_documents
    load_terms_db
  end

  def self.load_terms_db
    # TODO: Logging
    # this is in authority_browse/db.rb
    AuthorityBrowse.setup_terms_db
    term_fetcher = Solr::TermFetcher.new(field: "author_authoritative_browse")
    term_fetcher.each do |term, count|
      AuthorityBrowse.terms_db[:names].insert(term: term, count: count)
    end
  end

  def self.generate_solr_docs_from_graph
  end

  def self.generate_solr_docs_from_unmatched
  end
end

require "milemarker"
require "authority_browse/loc_authorities"
require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/normalize"
require "authority_browse/loc_skos/unmatched_entry"
require "authority_browse/models"
require "authority_browse/solr_document"
