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
  def self.authorities_graph_db
    @authorities_graph ||= 
      if ENV["APP_ENV"] == "test"
        Sequel.sqlite
      else
        Sequel.mysql2(host: ENV.fetch("DATABASE_HOST"), user: ENV.fetch("MARIADB_USER"), password: ENV.fetch("MARIADB_PASSWORD"), database: ENV.fetch("MARIADB_DATABASE"))
      end
  end
  def self.setup_authorities_graph_db
    authorities_graph_db.drop_table?(:names)
    authorities_graph_db.drop_table?(:names_see_also)
    authorities_graph_db.create_table(:names) do
      String :id, primary_key: true
      String :label  
    end
    authorities_graph_db.create_table(:names_see_also) do
      primary_key :id
      String :name_id
      String :see_also_id
    end
  end
  def self.terms_db
    @terms_db ||= Sequel.sqlite
  end
  def self.setup_terms_db 
    terms_db.drop_table?(:names)
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
