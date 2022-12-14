# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")
require "solr/term_fetcher"
require "zinzout"

url = ARGV.shift
field = ARGV.shift
filename = ARGV.shift
limit = (ARGV.shift || -1).to_i

unless url and field and url =~ /\Ahttp/
  puts "\n#{$0} -- print a list of term/number-of-documents pairs from solr"
  puts "as 'term\\tcount'"
  puts "\nUsage"
  puts "  #{$0} <url_to_core> <field_name> <output_file(.gz)> <optional_limit>"
  exit 1
end

termfetcher = Solr::TermFetcher.new(url: url, field: field)

last_one = limit - 1
Zinzout.zout(filename) do |out|
  termfetcher.each do |pair|
    outs.puts pair.join("\t")
  end
end
