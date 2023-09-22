require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent.parent + "lib").to_s
require "time"
require "authority_browse"

module SubjectToSolrDocsWrapper
  def self.run(dumpfile, termsfile, outfile)
    warn "Loading the dumpfile. 500k entries, each dot is 100k"
    s = Time.now
    subjects = AuthorityBrowse::LocSKOSRDF::Subject::Subjects.load(dumpfile)

    t = Time.now
    warn "\nDumpfile loaded in #{(t - s) / 60} minutes"

    warn "Load terms-with-counts file. 5.5M-ish terms, each dot is 100k."
    subjects.load_terms(termsfile)

    x = Time.now
    warn "\nTerms file loaded in #{(x - t) / 60} minutes"

    warn "Determine counts for the cross-references"
    subjects.add_xref_counts!

    d = Time.now
    warn "Cross-refs set up in #{d - x} seconds"

    warn "Dump solr docs to '#{outfile}'"
    Zinzout.zout(outfile) do |out|
      subjects.each { |s| out.puts s.to_solr_doc.to_json }
    end
    o = Time.now
    warn "Solr documents dumped in #{(o - d) / 60} minutes"
  end
end

dumpfile = ARGV.shift
termsfile = ARGV.shift
outfile = ARGV.shift

$stderr.sync = true

# :nocov:
if ENV["APP_ENV"] != "test"
  unless dumpfile && termsfile && outfile
    warn "\n\nUsage:"
    warn "    #{$0} <dumpfile> <termsfile> <outfile>"
    warn "\n\n where:"
    warn "      _dumpfile_ is produced by the skos_to_dumpfile script"
    warn "      _termsfiles_ is a tab-delimited set of term-count pairs"
    warn "      _outfile_ is where you want the resulting solr docs to be"
    warn ""
    warn "The whole process balloons up to about 8GB, so allocate accordingly"
    warn "\n\n"
    exit 1
  end

  unless Pathname.new(dumpfile).exist?
    warn "Dumpfile '#{dumpfile}' can't be found"
  end

  unless Pathname.new(termsfile).exist?
    warn "Terms file '#{termsfile}' can't be found"
  end

  SubjectToSolrDocsWrapper.run(dumpfile, termsfile, outfile)
end
# :nocov: