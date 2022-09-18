# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "zinzout"
require "milemarker"
require "logger"

LOGGER = Logger.new(STDERR)

solr_extract = ARGV.shift
db_name = ARGV.shift
unmatched_file = ARGV.shift

DB = AuthorityBrowse.db(db_name)
names = DB[:names]

# Need some sort of placeholder for stuff from teh dump that doesn't match any LoC
class AuthorityBrowse::UnmatchedEntry < AuthorityBrowse::GenericXRef
  def initialize(label:, count: 0, id: "ignored")
    super(label: label, count: count, id: id)
  end

  def to_solr
    {
      id: label,
      term: label,
      count: count,
      browse_field: "name",
      json: self.to_json
    }.to_json
  end
end

milemarker = Milemarker.new(name: "Match and add counts to db", logger: LOGGER, batch_size: 50_000)
milemarker.log "Zeroing out all the counts"
names.db.transaction { names.update(count: 0) }
milemarker.log "...done"

@match_text_match = names.select(:id).where(match_text: :$match_text, deprecated: false).prepare(:select, :match_text_match)
@deprecated_match = names.select(:id).where(match_text: :$match_text, deprecated: true).prepare(:select, :match_text_dep_match)
@increase_count = names.where(id: :$id).prepare(:update, :increase_count, count: Sequel[:count] + :$count)

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
records_read = 0

Zinzout.zout(unmatched_file) do |out|
  DB.transaction do
    Zinzout.zin(solr_extract).each_with_index do |line, i|
      records_read += 1
      pool.post(line, i) do
        line.chomp!
        components = line.split("\t")
        count = components.pop
        term = components.join(" ")
        unmatched = AuthorityBrowse::UnmatchedEntry.new(label: term, count: count, id: AuthorityBrowse::Normalize.match_text(term))
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

total_matches = names.where { count > 0 }.count

milemarker.log "Matches: #{total_matches}; Non matches: #{records_read - total_matches }"
