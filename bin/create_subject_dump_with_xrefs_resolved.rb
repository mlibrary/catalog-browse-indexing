# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"

infile = ARGV.shift
outfile = ARGV.shift

AuthorityBrowse::LocSKOSRDF::Subject::Subjects.convert(infile: infile, outfile: outfile)
