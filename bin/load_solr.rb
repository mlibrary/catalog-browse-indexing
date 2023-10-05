require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "milemarker"
require "logger"

AuthorityBrowse.load_names_from_biblio
