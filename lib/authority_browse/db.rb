# frozen_string_literal: true

require "sequel"
require "pathname"

module AuthorityBrowse
  DB_PATH = ENV["AUTHORITY_BROWSE_DB"] || "authorities.sqlite3"

  # @return [Sequel::SQLite::Dataset]
  def self.db(file)
    path = Pathname.new(file).realdirpath
    @db ||= if IS_JRUBY
      require "jdbc/sqlite3"
      Sequel.connect("jdbc:sqlite://#{path}")
    else
      require "sqlite3"
      Sequel.connect("sqlite://#{path}")
    end
  end
  def self.terms_db
    @terms_db ||= Sequel.sqlite
  end
  def self.setup_terms_db 
    terms_db.create_table :names do
      String :term, primary_key: true
      Integer :count
      Boolean :in_authority_graph, default: false
    end
    #terms_db.create_table :subjects do
      #String :term, primary_key: true
      #Integer :count
      #Boolean :in_authority_graph, default: false
    #end
  end
end
