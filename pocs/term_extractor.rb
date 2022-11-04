#!/usr/bin/env ruby

if ARGV.empty?
  filename = $0
  puts "#{filename}: Extract term/doc-counts from solr"
  puts "Use: SOLR_URL=http://blahblah #{filename} nameOfSolrField"
  exit 1
end

core_url = ENV["SOLR_URL"] || "http://search-prep.umdl.umich.edu:8025/solr/biblio/"

URL = core_url.chomp("/") + "/terms"

puts "URL is #{URL}"

BATCH = 50_000

require "json"
require "net/http"
require "uri"

FIELD = ARGV.shift
OUTFILE = "#{FIELD}_browse_terms.tsv"

ARGS = {"terms.fl" => FIELD, "terms.sort" => "index", "terms.limit" => BATCH, "json.nl" => "arrarr", "terms.lower.incl" => false}

TARGET = URI(URL)

def get(last = "")
  y = JSON.parse Net::HTTP.post_form(TARGET, ARGS.merge({"terms.lower" => last})).body
  vals = y["terms"][FIELD]
  return [], last if vals.empty?
  [vals, vals.last.first]
end

def output_values(vals)
  vals.map { |a| "#{a.first}\t#{a.last}" }.join("\n")
end

puts "Extracting terms for field #{FIELD} into file '#{OUTFILE}', batches of #{BATCH}"

total = 0

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

File.open(OUTFILE, "w:utf-8") do |out|
  last = ""
  loop do
    vals, last = get(last)
    print "."
    out.puts output_values(vals)
    total += vals.size
    break if vals.size < BATCH
  end
end

puts "Done"

end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

elapsed = Time.at(end_time - start_time).utc
hours = elapsed.strftime("%H")
minutes = elapsed.strftime("%M")
seconds = elapsed.strftime("%S.%2N")

elapsed_components = [hours, minutes, seconds]
while elapsed_components.first == "00"
  elapsed_components.shift
end

puts "#{FIELD}: #{total} terms extracted in #{elapsed_components.join(":")}"
