# frozen_string_literal: true

require 'zinzout'
require 'httpx'
require "json"
require 'date'
require 'concurrent'

# Given an extract created by `extract_from_naf`, dump the resulting
# documents into a solr core.

url = ENV["NAF_SOLR"]
file = ARGV.shift


unless url and file and File.exist?(file)
  warn "Need the url to the NAF core in env variable NAF_SOLR"
  warn "and a filename passed on the command line."
  exit(1)
end

url = url.gsub(%r(/\Z), '') + "/update?commit=true"

client = HTTPX.with(headers: {'Content-Type' => 'application/json'})
input = Zinzout.zin(file)

pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: 4,
  max_threads: 4,
  max_queue: 10,
  fallback_policy: :caller_runs
)

batch = 1000
tick = 10_000 / batch
i = 1

puts "Sending documents to #{url}"
while docs = input.take(batch)
  docs.map!{|x| JSON.parse(x)}
  docs.map! do |doc|
    doc["record_type"] = doc.delete("type")
    doc["browse_field"] = "naf"
    doc
  end
  i += 1
  print '.'
  pool.post(i) do |i|
    resp = client.post(url, json: docs)
    total = batch * i
    puts "#{DateTime.now} #{batch * i}" if i % tick == 0
  end

end

# tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
pool.shutdown
# now wait for all work to complete, wait as long as it takes
pool.wait_for_termination

puts DateTime.now