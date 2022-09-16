# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s
require "authority_browse"

# Given a database that:
#   * has been created (once in the past) with names_skos_to_db
#   * has had actual counts added to it via names_add_counts_to_db
#     (using a file created from calling dump_terms_and_counts)
#  ...go through and update the json of all the items that have xrefs
# so the counts are attached to them as well.
#
# <field name="loc_id" type="string" stored="true" indexed="true" multiValued="false" />
# <field name="browse_field" type="string" stored="true" indexed="true" multiValued="false" docValues="true"/>
# <field name="term" type="browse_match" indexed="true" stored="true" multiValued="false"/>
# <field name="search_key" type="string" indexed="true" stored="true" multiValued="false"/>
# <field name="sort_key"   type="string" indexed="true" stored="true" multiValued="false"/>
# <field name="alternate_forms" type="string" stored="true" indexed="false" multiValued="true"/>
# <field name="see_also" type="browse_match" indexed="true" stored="true" multiValued="true"/>
# <field name="incoming_see_also" type="browse_match" indexed="true" stored="true" multiValued="true"/>
#
# <field name="count" type="int" stored="true" indexed="true" multiValued="false"/>
#

# For any item that has xrefs, we do the following:
#  * hydrate its JSON
#  * for each of its see_also entries
#    * grab the counts for the ids
#    * update the see_also with its count
#    * re-save the JSON
#
# Then, dump every entry in the database

db_name = ARGV.shift
output_file = ARGV.shift

DB = AuthorityBrowse.db(db_name)
names = DB[:names]

save_back_json = names.where(id: :$id).prepare(:update, :json_update, json: :$json)
get_by_id = names.where(id: :$id).limit(1).prepare(:select, :fetcher)

$stderr.puts "Starting copy of counts for see_also xrefs into the json"
# names.db.transaction do
#   names.where(xrefs: true).where { count > 0 }.each_with_index do |rec, i|
#     id = rec[:id]
#     e = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(rec[:json])
#     e.see_also.values.each do |sa|
#       resp = get_by_id.call(id: sa.id)
#       sa.count = (resp.empty? ? 0 : resp.first.count)
#     end
#     e.incoming_see_also.values.each do |isa|
#       isa.count = get_by_id.call(id: isa.id)&.first[:count]
#     end
#     save_back_json.call(id: id, json: e.to_json)
#     $stderr.puts "%9d %s" % [i, DateTime.now] if i % 1_000 == 0
#   end
# end

# For each entry with count > 0, set the internal count to whatever is in the database
# and dump to stdout

require 'concurrent'
lock = Concurrent::ReadWriteLock.new

pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: 8,
  max_threads: 8,
  max_queue: 200,
  fallback_policy: :caller_runs
)

$stderr.puts "Starting dump of all records with count > 0"

$stderr.sync = true

Zinzout.zout(output_file) do |out|
  names.where { count > 0 }.each_with_index do |rec, i|
    pool.post(rec, i) do
      e = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(rec[:json])
      e.count = rec[:count]
      lock.with_write_lock { out.puts e.to_solr_doc.to_json }
      $stderr.puts "%9d %s" % [i, DateTime.now] if i % 100_000 == 0
    end
  end
end

pool.shutdown
pool.wait_for_termination
