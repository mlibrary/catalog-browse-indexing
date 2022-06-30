# frozen_string_literal: true

$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")

$stdout.sync = true

require 'zinzout'
require 'date'
require 'concurrent'
require 'solr/term_fetcher'
require 'authority_browse/connection'
require 'authority_browse/author'

# Do the following:
# * get an author_term/count from production solr
# * see if it matches anything in the NAF
#   - if so, add the count to the NAF data and index it in the browse index
#   - if not, just send a minimal record to the browse index

author_term_source_url = "http://julep-1:8026/solr/biblio"
naf_url = "http://julep-1:8026/solr/naf"
# author_browse_url = "http://julep-1:8026/solr/author_browse"
author_browse_url = "http://localhost:8025/solr/authority_browse"

term_field = 'authorStr'
naf_field = "author"

authors = Solr::TermFetcher.new(url: author_term_source_url, field: term_field, batch_size: 1000)
updater = AuthorityBrowse::SolrUploader.new(url: author_browse_url, batch_size: 150)
matcher = AuthorityBrowse::Author::NAFMatcher.new(url: naf_url, field: naf_field)

authors.each_with_index do |pair, i|
  puts "\n#{DateTime.now.iso8601}\t#{i}" if i % 1000 == 0
  break if i >= 10_000
  author = pair.first
  count = pair.last
  e = Concurrent::Promises.future_on(:io, author, count) do |a, c|
    naf = matcher.find_naf(a)
    entry = if naf
          print '*'
          AuthorityBrowse::Author::Entry.from_naf_hash(naf) do |naf_entry|
            naf_entry.count = c
          end
        else
          AuthorityBrowse::Author::Entry.new(author: a, count: c)
        end
    entry.to_hash
  end
  updater.add(e)
end

updater.send_dregs_and_close
