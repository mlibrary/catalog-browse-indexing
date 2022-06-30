# frozen_string_literal: true

require "httpx"
require "json"
require "zinzout"
require "concurrent"

# Take the output of extract_naf_labels.rb and send them to a solr
# configured with the stuff in `./solr`

filename = ARGV.shift || "data/author_file.jsonld"

json_endpoint = "http://search-prep.umdl.umich.edu:8025/solr/author_browse/update/json"

# @!attribute pool
#   @return [Concurrent::ThreadPoolExecutor] the pool
pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: 8,
  max_threads: 8,
  max_queue: 200,
  fallback_policy: :caller_runs
)
slice = 2500
batches = Concurrent::AtomicFixnum.new(0)

Zinzout.zin(filename).each.each_slice(slice) do |lines|
  lines.map! { |x| JSON.parse(x.chomp) }
  lines.each do |h|
    h["id"] = h["author"] # just use the author as a sort key for now
    h.delete("_version_")
    h["record_type"] = "browse"
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
