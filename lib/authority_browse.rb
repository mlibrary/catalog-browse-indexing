# frozen_string_literal: true

require_relative "solr/term_fetcher"
require "milemarker"
require "logger"
require "byebug"

module AuthorityBrowse
  IS_JRUBY = (RUBY_ENGINE == "jruby")
  def self.generate_and_send_solr_documents
    load_terms_db
    docs = generate_solr_docs_from_graph + generate_solr_docs_from_unmatched
    AuthorityBrowse::SolrUploader.new(collection: "authority_browse").upload(docs)
  end

  def self.test_threaded_load
    require "concurrent"

    pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: 4,
      max_threads: 4,
      max_queue: 200,
      fallback_policy: :caller_runs
    )
    batch_size = 10_000
    docs = []
    docs = Concurrent::Array.new
    uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")
    milemarker = Milemarker.new(batch_size: 10_000, name: "process names", logger: Logger.new($stdout))
    milemarker.log "start processing names"
    milemarker.threadsafify!

    Name.limit(10_000).all.each do |n|
      pool.post(n) do |name|
        milemarker.increment_and_log_batch_line
        name_obj = AuthorityBrowse::AuthorityGraphSolrDocument.new(name)
        if name_obj.in_term_db?
          docs.push(name_obj.to_solr_doc)
          if docs.count == batch_size
            puts "uploading solr docs"
            uploader.upload(docs)
            docs.clear
          end
        end
      end
    end
    milemarker.log "uploading last solr docs"
    uploader.upload(docs)
    milemarker.log "commit solr docs"
    uploader.commit
    milemarker.log_final_line
  end

  def self.test_load_to_solr
    batch_size = 10_000
    docs = []
    count = 0
    uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")
    milemarker = Milemarker.new(batch_size: 10_000, name: "process names", logger: Logger.new($stdout))
    milemarker.log "start processing names"
    Name.limit(10_000).all.each do |name|
      milemarker.increment_and_log_batch_line
      name_obj = AuthorityBrowse::AuthorityGraphSolrDocument.new(name)
      if name_obj.in_term_db?
        docs.push(name_obj.to_solr_doc)
        count += 1
        if count == batch_size
          puts "uploading solr docs"
          uploader.upload(docs)
          count = 0
          docs.clear
        end
      end
    end
    milemarker.log "uploading last solr docs"
    uploader.upload(docs)
    milemarker.log "commit solr docs"
    uploader.commit
    milemarker.log_final_line
  end

  def self.test_load
    # load_terms_db_from_file("/app/data/names/20230418/aab.tsv.gz")
    milemarker = Milemarker.new(batch_size: 10_000, name: "process names", logger: Logger.new($stdout))
    milemarker.log "start processing names"
    names = Name.limit(100_000).filter_map do |name|
      milemarker.increment_and_log_batch_line
      name_obj = AuthorityBrowse::AuthorityGraphSolrDocument.new(name)
      name_obj.to_solr_doc if name_obj.in_term_db?
    end
    puts names.count
    milemarker.log_final_line
  end

  def self.load_terms_db_from_file(file)
    milemarker = Milemarker.new(batch_size: 100_000, name: "Add terms to term_db", logger: Logger.new($stdout))
    milemarker.log "Start loading terms db"
    AuthorityBrowse.setup_terms_db
    Zinzout.zin(file).each_slice(100_000) do |slice|
      AuthorityBrowse.terms_db.transaction do
        slice.each do |line|
          components = line.chomp.split("\t")
          count = components.pop.to_i
          term = components.join(" ")
          AuthorityBrowse.terms_db[:names].insert(term: term, count: count)
          milemarker.increment_and_log_batch_line
        end
      end
    end
    milemarker.log_final_line
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
      milemarker.increment_and_log_batch_line
      name_obj = AuthorityBrowse::AuthorityGraphSolrDocument.new(name)
      name_obj.to_solr_doc if name_obj.in_term_db?
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
