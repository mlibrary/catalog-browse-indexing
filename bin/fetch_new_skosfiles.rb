# frozen_string_literal: true

require "pathname"
here = Pathname.new(__dir__)
$LOAD_PATH.unshift here.parent + "lib"


names_url = "https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz"
subjects_url = "https://id.loc.gov/download/authorities/subjects.skosrdf.jsonld.gz"
target_dir = here.parent + "data/LoC/source"

names_file = (target_dir + "names.skosrdf.jsonld.gz").to_s
subjects_file = (target_dir + "subjects.skosrdf.jsonld.gz").to_s

system("curl -L #{subjects_url} >#{subjects_file}")
system("curl -L #{names_url}, >#{names_file}")


