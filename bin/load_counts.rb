require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "milemarker"
require "logger"
require "byebug"

@names = AuthorityBrowse.db[:names]
@from_biblio = AuthorityBrowse.db[:names_from_biblio]

# @match_text_match = @names.select(:id).where(match_text: :$match_text, deprecated: false).prepare(:select, :match_text_match)

# @deprecated_match = @names.select(:id).where(match_text: :$match_text, deprecated: true).prepare(:select, :match_text_dep_match)

@increase_count = @names.where(id: :$id).prepare(:update, :increase_count, count: (Sequel[:count] + :$count))

def best_match(unmatched)
  resp = @names.select(:id).where(match_text: unmatched, deprecated: 0)
  if resp.count > 0
    resp
  else
    @names.select(:id).where(match_text: unmatched, deprecated: 1)
  end
end

# query = "select match_text, sum(count) as total_count from names_from_biblio group by match_text;"

require "concurrent"

threads = 4
pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: threads,
  max_threads: threads,
  max_queue: 200,
  fallback_policy: :caller_runs
)

milemarker = Milemarker.new(name: "Match and add counts to db", logger: Logger.new($stdout), batch_size: 1_000)
milemarker.log "Zeroing out all the counts from the last run. Can take 5mn."
@names.db.transaction { @names.update(count: 0) }

milemarker.threadsafify!

milemarker.log "start loading counts"
@from_biblio.each do |row|
  pool.post(row) do |value|
    resp = best_match(value[:match_text])
    if resp.count > 0
      id = resp.first[:id]
      @increase_count.call(id: id, count: value[:count])
      @from_biblio.where(id: value[:id]).update(name_id: id)
    end
    milemarker.increment_and_log_batch_line
  end
end

pool.shutdown
pool.wait_for_termination
milemarker.log_final_line
