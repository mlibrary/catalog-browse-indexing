#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")

require "authority_browse/connection"
require "json"

url = ARGV.shift
fieldname = ARGV.shift

connection = AuthorityBrowse::Connection.new

@query = (ENV["SOLR_QUERY"] or "*:*")

def payload(fieldname, offset = 0, page_size = 20)
  {
    query: @query,
    "limit" => 0,
    facet: {
      fieldname => {
        type: "terms",
        field: fieldname,
        "limit" => page_size,
        allBuckets: true,
        offset: offset,
        sort: "index asc"
      }
    }
  }
end

handler = url.chomp("/") + "/select"

$stderr.puts "Getting '#{fieldname}' from #{handler}"
page_size = 5_000
offset = 0
loop do
  p = payload(fieldname, offset, page_size)
  resp = connection.post(handler, json: p)
  buckets = resp.json["facets"][fieldname]["buckets"]
  buckets.each do |h|
    puts "#{h["val"]}\t#{h["count"]}"
  end
  offset += page_size
  $stderr.print "."
  break if buckets.size < page_size
end

