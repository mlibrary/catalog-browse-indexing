# frozen_string_literal: true

require_relative "solr/term_fetcher"
require "milemarker"
require "logger"

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
  def self.generate_and_send_solr_documents
    load_terms_db
    docs = generate_solr_docs_from_graph + generate_solr_docs_from_unmatched
    AuthorityBrowse::SolrUploader.new(collection: "authority_browse").upload(docs)
  end

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

  def self.generate_solr_docs_from_graph
    milemarker = Milemarker.new(batch_size: 100_000, name: "generate solr docs from names graph", logger: Logger.new($stdout))
    milemarker.log "Start generating solr docs from graph"
    Name.all.filter_map do |name|
      name_obj = AuthorityBrowse::AuthorityGraphSolrDocument.new(name)
      name_obj.to_solr_doc if name_obj.in_term_db?
      milemarker.increment_and_log_batch_line
    end
    milemarker.log_final_line
  end

  def self.generate_solr_docs_from_unmatched
    milemarker.log "Start generating solr docs from unmatched names"
    milemarker = Milemarker.new(batch_size: 100_000, name: "generate solr docs from unmatched names", logger: Logger.new($stdout))
    AuthorityBrowse.terms_db.where(in_authority_graph: false).map do |term|
      AuthorityBrowse::UnmatchedSolrDocument.new(term).to_solr_doc
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
