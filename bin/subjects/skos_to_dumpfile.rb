# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent.parent + "lib").to_s

require "authority_browse"

skosfile = ARGV.shift
dumpfile = ARGV.shift



unless skosfile and dumpfile
  puts "\n#{$0} -- Turn a subjects.skosrdf.jsonl(.gz) file into a subjects dump"
  puts "\nUsage"
  puts "  #{$0} <skosfile> <dumpfile.jsonl(.gz)>"
  exit 1
end

begin
  AuthorityBrowse::LocSKOSRDF::Subject::Subjects.convert(infile: skosfile, outfile: dumpfile)
rescue => e
  require 'pry'; binding.pry
end



