# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent.parent + "lib").to_s

require "date"
require "zinzout"
require "milemarker"
require "logger"

require "authority_browse"

if ARGV.size != 3
  puts "\nUsage"
  puts "  #{$0} <path to solr terms extract> <path to sqlite3 dbfile> <output_directory>"
  puts
  exit 1
end

LOGGER = Logger.new(STDERR)

# Naming things
solr_extract = ARGV.shift
db_name = ARGV.shift
target_dir = Pathname.new(ARGV.shift)

yyyymmdd = DateTime.now.strftime("%Y_%m_%d")
unmatched_dump = target_dir + "unmatched_as_solr_#{yyyymmdd}.jsonl.gz"
matched_dump = target_dir + "matched_as_solr_#{yyyymmdd}.jsonl.gz"

# Database connection
DB = AuthorityBrowse.db(db_name)
names = DB[:names]

# Logging
milemarker = Milemarker.new(name: "Match and add counts to db", logger: LOGGER, batch_size: 50_000)

# Zero out the counts, for replacement with the new file
milemarker.log "Zeroing out all the counts"
names.db.transaction { names.update(count: 0) }
milemarker.log "...done zeroing"

# Prepare statements to try to match terms from the file
@match_text_match = names.select(:id).where(match_text: :$match_text, deprecated: false).prepare(:select, :match_text_match)
@deprecated_match = names.select(:id).where(match_text: :$match_text, deprecated: true).prepare(:select, :match_text_dep_match)
@increase_count = names.where(id: :$id).prepare(:update, :increase_count, count: (Sequel[:count] + :$count))

# First try to match against a non-deprecated entry. Fall back to deprecated if we can't find one.
# @param [AuthorityBrowse::GenericXRef] unmatched
def best_match(unmatched)
  resp = @match_text_match.call(match_text: unmatched.match_text)
  if resp.count > 0
    resp
  else
    @deprecated_match.call(match_text: unmatched.match_text)
  end
end

require 'concurrent'
lock = Concurrent::ReadWriteLock.new

pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: 8,
  max_threads: 8,
  max_queue: 200,
  fallback_policy: :caller_runs
)

milemarker.log "Reading the solr extract. Matches get counts, non-matches are written out to file"

milemarker.threadsafify!

def parse_line(ln)
  components = ln.chomp.split("\t")
  count = components.pop
  term = components.join(" ")
  return count, term
end

records_read = 0 # For logging
Zinzout.zout(unmatched_dump) do |out|
  DB.transaction do
    Zinzout.zin(solr_extract).each_with_index do |line, i|
      records_read += 1
      pool.post(line, i) do |ln, i|
        count, term = parse_line(ln)
        unmatched = AuthorityBrowse::LocSKOSRDF::UnmatchedEntry.new(label: term, count: count, id: AuthorityBrowse::Normalize.match_text(term))
        resp = best_match(unmatched)
        case resp.count
          when 0
            lock.with_write_lock { out.puts unmatched.to_solr }
          else
            rec = resp.first
            @increase_count.call(id: rec[:id], count: count)
        end
        milemarker.increment_and_log_batch_line
      end
    end
  end

  pool.shutdown
  pool.wait_for_termination
  milemarker.log_final_line
end
