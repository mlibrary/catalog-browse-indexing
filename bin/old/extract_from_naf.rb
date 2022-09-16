# frozen_string_literal: true

$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")

require "authority_browse/author"
require "zinzout"

# Pull the data we want out of the skos data from the LoC and
# dump it as jsonl

filename = ARGV.shift

Zinzout.zin(filename).each do |line|
  a =  AuthorityBrowse::Author::NAFSkosJsonld::Entry.new(line)
  next if a.deprecated?
  puts a.to_json
end

