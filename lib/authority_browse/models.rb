require "sequel"
Sequel::Model.db = AuthorityBrowse.authorities_graph_db
require_relative "models/name"
