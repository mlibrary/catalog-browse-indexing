# frozen_string_literal: true

$LOAD_PATH.unshift(Pathname.new(__dir__).parent + "lib")

$stdout.sync = true

require "zinzout"
require "date"
require "concurrent"
require "solr/term_fetcher"
require "authority_browse/connection"
require "authority_browse/author"

# Do the following:
# * get an author_term/count from production solr
# * see if it matches anything in the NAF
#   - if so, add the count to the NAF data and index it in the browse index
#   - if not, just send a minimal record to the browse index

author_term_source_url = ENV["BROWSE_SOURCE_CORE_URL"] || "http://localhost:8026/solr/biblio"
naf_url = ENV["BROWSE_NAF_CORE_URL"] || "http://localhost:8026/solr/naf"
author_browse_url = ENV["BROWSE_TARGET_CORE_URL"] || "http://localhost:8026/solr/author_browse"

term_field = "authorStr"
naf_field = "author"

authors = Solr::TermFetcher.new(url: author_term_source_url, field: term_field, batch_size: 2000)
updater = AuthorityBrowse::SolrUploader.new(url: author_browse_url, batch_size: 250)
matcher = AuthorityBrowse::Author::NAFMatcher.new(url: naf_url, field: naf_field)

authors.each_with_index do |pair, i|
  puts "\n#{DateTime.now.iso8601}\t#{i}" if i % 50_000 == 0
  author = pair.first
  count = pair.last
  e = Concurrent::Promises.future_on(:io, author, count) do |a, c|
    naf = matcher.find_naf(a)
    entry = if naf
      AuthorityBrowse::Author::Entry.from_naf_hash(naf) do |naf_entry|
        naf_entry.count = c
      end
    else
      AuthorityBrowse::Author::Entry.new(author: a, count: c)
    end
    entry.to_h
  end
  updater.add(e)
end

updater.send_dregs_and_close
