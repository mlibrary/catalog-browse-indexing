require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "logger"
require "byebug"

def duration(seconds)
  t = seconds
  "%02d:%02d:%02d:%02d" % [t / 86400, t / 3600 % 24, t / 60 % 60, t % 60]
end
logger = Logger.new($stdout)

logger.info "Zeroing out all the counts from the last run. Can take 5min."
start = Time.now
AuthorityBrowse.db.transaction { AuthorityBrowse.db[:names].update(count: 0) }
finish = Time.now
logger.info "finished zeroing out counts"
logger.info "duration: #{duration(finish - start)}"

# update names with counts from names_from_biblio
update_names_counts_statement = <<~SQL
  UPDATE names AS n
  SET count = (
    SELECT sum(count) 
    FROM names_from_biblio AS nfb
    WHERE n.match_text = nfb.match_text);
SQL

logger.info "updating names with counts"
start = Time.now
AuthorityBrowse.db.run(update_names_counts_statement)
finish = Time.now
logger.info "finished updating names with counts"
logger.info "duration: #{duration(finish - start)}"

## update names_from_biblio with corresponding ids from names
# statement = <<-SQL
# UPDATE names_from_biblio as nfb
# SET name_id = (
# SELECT n.id
# FROM names AS n
# INNER JOIN names_from_biblio AS nfb_inner
# WHERE n.match_text = nfb_inner.match_text
# AND n.match_text = nfb.match_text
# LIMIT 1
# );
# SQL

# UPDATE names_from_biblio AS nfb
# SET name_id = (
# SELECT id
# FROM names AS n
# WHERE n.match_text = nfb.match_text
# LIMIT 1);"
