# frozen_string_literal: true


$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")
require "solr/term_fetcher"

url = ARGV.shift
field = ARGV.shift
limit = (ARGV.shift || -1).to_i


unless url and field and url=~/\Ahttp/
  puts "\n#{$0} -- print a list of term/number-of-documents pairs from solr"
  puts "as 'term\\tcount'"
  puts "\nUsage"
  puts "  #{$0} <url_to_core> <field_name> <optional_limit>"
  exit 1
end

termfetcher = Solr::TermFetcher.new(url: url, field: field)

last_one = limit - 1
termfetcher.each_with_index do |pair, i|
  puts pair.join("\t")
  break if i == last_one
end
