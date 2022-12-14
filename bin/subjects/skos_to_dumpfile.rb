# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"

skosfile = ARGV.shift
dumpfile = ARGV.shift

unless skosfile and dumpfile
  puts "\n#{$0} -- Turn a subjects.skosrdf.jsonl(.gz) file into a subjects dump"
  puts "\nUsage"
  puts "  #{$0} <skosfile> <dumpfile.jsonl(.gz)>"
  exit 1
end


AuthorityBrowse::LocSKOSRDF::Subject::Subjects.convert(infile: infile, outfile: outfile)

