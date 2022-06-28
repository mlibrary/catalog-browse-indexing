# frozen_string_literal: true

$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib")

require "authority_browse/author"
require "zinzout"

filename = ARGV.shift

Zinzout.zin(filename).each do |line|
  a =  AuthorityBrowse::Author::NAFSkosJsonld::Entry.new(line)
  next if a.deprecated?
  puts a.to_json
end

