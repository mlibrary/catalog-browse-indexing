# frozen_string_literal: true

require "httpx"
require "json"
require "zinzout"
require "concurrent"

# Take the output of extract_naf_labels.rb and send them to a solr
# configured with the stuff in `./solr`

filename = ARGV.shift || "data/naf.jsonld"

json_endpoint = "http://search-prep.umdl.umich.edu:8025/solr/lcnaf/update/json"

pool = Concurrent::FixedThreadPool.new(5)

slice = 2500
batches = Concurrent::AtomicFixnum.new(0)

Zinzout.zin(filename).each.each_slice(slice) do |lines|
  lines.map! { |x| JSON.parse(x) }
  lines.map! do |h|
    doc = {author: h["label"], id: h["id"]}
    if h["targets"]
      doc["see_instead"] = h["targets"]
    end
    al = h["alternate_labels"]
    unless al.nil? || al.empty?
      doc["alt_labels"] = al
    end
    doc
  end
  pool.post do
    resp = HTTPX.post(json_endpoint, json: lines.dup)
    if resp.status == 200
      print "."
    else
      print "*"
    end
    cnt = batches.increment * slice
    puts cnt if cnt % 50_000 == 0
  end
end

# tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
pool.shutdown
# now wait for all work to complete, wait as long as it takes
pool.wait_for_termination
