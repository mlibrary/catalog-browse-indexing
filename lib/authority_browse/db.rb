# frozen_string_literal: true

require "sequel"
require "pathname"

module AuthorityBrowse
  def self.db
    @db ||=
      if ENV["APP_ENV"] == "test"
        Sequel.sqlite
      else
        Sequel.mysql2(host: ENV.fetch("DATABASE_HOST"), user: ENV.fetch("MARIADB_USER"), password: ENV.fetch("MARIADB_PASSWORD"), database: ENV.fetch("MARIADB_DATABASE"))
        # Sequel.sqlite("authority_graph.db")
      end
  end

  def self.setup_db
    db.drop_table?(:names)
    db.drop_table?(:names_see_also)
    db.drop_table?(:names_from_biblio)
    db.create_table(:names) do
      String :id, primary_key: true
      String :label, text: true
      String :match_text, text: true, index: true
      Integer :count, default: 0
      Boolean :deprecated, default: false, index: true
    end
    db.create_table(:names_see_also) do
      primary_key :id
      String :name_id, index: true
      String :see_also_id
    end
    db.create_table(:names_from_biblio) do
      String :term, primary_key: true
      String :match_text, index: true
      Integer :count, default: 0
      String :name_id, default: nil
    end
  end

  def self.reset_names_from_biblio
    db.drop_table?(:names_from_biblio)
    db.create_table(:names_from_biblio) do
      String :term, primary_key: true
      String :match_text, index: true
      Integer :count, default: 0
      String :name_id, default: nil
    end
  end

  # @return [Sequel::SQLite::Dataset]
  def self.db_old(file)
    path = Pathname.new(file).realdirpath
    @db_old ||= if IS_JRUBY
      require "jdbc/sqlite3"
      Sequel.connect("jdbc:sqlite://#{path}")
    else
      require "sqlite3"
      Sequel.connect("sqlite://#{path}")
    end
  end
end
