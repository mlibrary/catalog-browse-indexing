# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s
require "authority_browse"
require "milemarker"
require "logger"

# Given a database that:
#   * has been created (once in the past) with names_skos_to_db
#   * has had actual counts added to it via names_add_counts_to_db
#     (using a file created from calling dump_terms_and_counts)
#  ...go through and update the json of all the items that have xrefs
# so the counts are attached to them as well.

# Once we've got counts on each line in the database, we propagate those
# counts to live inside the JSON representation of the see_also structures.
# So for any item that has xrefs, we do the following:
#  * hydrate its JSON
#  * for each of its see_also entries
#    * grab the counts for that entry in the database
#    * update the see_also with that count
#  * re-save the JSON for our original object
#

# Finally, dump every entry in the database with a count > 0

LOGGER = Logger.new(STDERR)

db_name = ARGV.shift
output_file = ARGV.shift

DB = AuthorityBrowse.db(db_name)
names = DB[:names]

# Prepared statements
save_back_json = names.where(id: :$id).prepare(:update, :json_update, json: :$json)
get_by_id = names.where(id: :$id).limit(1).prepare(:select, :fetcher)

milemarker = Milemarker.new(name: "Put counts from xrefs in json", batch_size: 1000, logger: LOGGER)

milemarker.log "Starting xref processing"
names.db.transaction do
  names.where(xrefs: true).where { count > 0 }.each_with_index do |rec, i|
    id = rec[:id]
    e = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(rec[:json])
    e.see_also.values.each do |sa|
      sa.count = get_by_id.call(id: sa.id)&.first[:count]
    end
    e.incoming_see_also.values.each do |isa|
      isa.count = get_by_id.call(id: isa.id)&.first[:count]
    end
    save_back_json.call(id: id, json: e.to_json)
    milemarker.increment_and_log_batch_line
  end
end
milemarker.log_final_line

# For each entry with count > 0, set the internal count to whatever is in the database
# and dump to stdout

milemarker = Milemarker.new(name: "Export matched records with counts", batch_size: 100_000, logger: LOGGER)
milemarker.log "Starting dump of all records with count > 0 to #{output_file}"

begin
  Zinzout.zout(output_file) do |out|
    names.where { count > 0 }.each_with_index do |rec, i|
      e = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(rec[:json])
      e.count = rec[:count]
      out.puts e.to_solr_doc.to_json
      milemarker.increment_and_log_batch_line
    end
  end
rescue => err
  require "pry"; binding.pry
end

milemarker.log_final_line
exit 0