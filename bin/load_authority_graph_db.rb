require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s
require "authority_browse"
AuthorityBrowse.setup_authorities_graph_db

require "milemarker"
require "logger"

db = AuthorityBrowse.authorities_graph_db
names_table = AuthorityBrowse.authorities_graph_db[:names]
see_also_table = AuthorityBrowse.authorities_graph_db[:names_see_also]

logger = Logger.new($stdout)
# milemarker = Milemarker.new(batch_size: 100_000, name: "Add skos data to database", logger: logger)
# milemarker.log "Starting skos parsing"

# Zinzout.zin("./data/names.skosrdf.jsonld.gz").each do |line|
# AuthorityBrowse::LocAuthorities::Entry.new(JSON.parse(line)).save_to_db
# milemarker.increment_and_log_batch_line
# end
milemarker = Milemarker.new(batch_size: 100_000, name: "adding to entries array", logger: logger)
milemarker.log "Starting adding to entries array"
Zinzout.zin("./data/names.skosrdf.jsonld.gz").each_slice(100_000) do |slice|
  # Zinzout.zin("./data/smaller.jsonld.gz").each_slice(100_000) do |slice|
  entries = slice.map do |line|
    AuthorityBrowse::LocAuthorities::Entry.new(JSON.parse(line))
  end
  db.transaction do
    entries.each do |entry|
      names_table.insert(id: entry.id, label: entry.label, match_text: entry.match_text)
    end
  end

  db.transaction do
    entries.each do |entry|
      if entry.see_also_ids?
        entry.see_also_ids.each do |see_also_id|
          see_also_table.insert(name_id: entry.id, see_also_id: see_also_id)
        end
      end
    end
  end
  milemarker.increment(100_000)
  milemarker.on_batch { milemarker.log_batch_line }
end

milemarker.log_final_line
