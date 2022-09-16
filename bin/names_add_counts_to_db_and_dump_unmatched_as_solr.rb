# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "zinzout"

solr_extract = ARGV.shift
db_name = ARGV.shift

DB = AuthorityBrowse.db(db_name)
names = DB[:names]

class AuthorityBrowse::UnmatchedEntry < AuthorityBrowse::GenericXRef
  def initialize(label:, count: 0)
    super(label: label, count: count, id: "ignored")
  end

  def to_solr
    {
      id: sort_key,
      term: label,
      count: count,
      sort_key: sort_key,
      browse_field: "name",
      json: self.to_json
    }.to_json
  end
end

$stderr.puts "Zeroing out all the counts"
names.db.transaction { names.update(count: 0) }
$stderr.puts "...done"

@sort_key_match = names.select(:id).where(search_key: :$search_key, deprecated: false).prepare(:select, :sort_key_match)
@deprecated_match = names.select(:id).where(search_key: :$search_key, deprecated: true).prepare(:select, :search_key_dep_match)
@increase_count = names.where(id: :$id).prepare(:update, :increase_count, count: Sequel[:count] + :$count)

no_matches = 0
single_matches = 0
multi_matches = 0

# First try to match against a non-deprecated entry. Fall back to deprecated if we can't find one.
# @param [AuthorityBrowse::GenericXRef] unmatched
def best_match(unmatched)
  resp = @sort_key_match.call(sort_key: unmatched.sort_key)
  if resp.count > 0
    resp
  else
    @deprecated_match.call(sort_key: unmatched.sort_key)
  end
end

require 'concurrent'
require "logger"

lock = Concurrent::ReadWriteLock.new


pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: 8,
  max_threads: 8,
  max_queue: 200,
  fallback_policy: :caller_runs
)

DB.transaction do
  Zinzout.zin(solr_extract).each_with_index do |line, i|
    pool.post(line, i) do
      line.chomp!
      term, count = line.split("\t")
      unmatched = AuthorityBrowse::UnmatchedEntry.new(label: term, count: count)
      resp = best_match(unmatched)
      case resp.count
      when 0
        lock.with_write_lock { puts unmatched.to_solr }
      else
        rec = resp.first
        @increase_count.call(id: rec[:id], count: count)
      end
      $stderr.puts "%9d %s %d / %d / %d" % [i, DateTime.now, no_matches, single_matches, multi_matches] if i % 100_000 == 0
    end
  end
end

pool.shutdown
pool.wait_for_termination

$stderr.puts <<~DONE
  No matches: #{no_matches}
  Single matches: #{single_matches}
  Multi matches: #{multi_matches}
DONE

