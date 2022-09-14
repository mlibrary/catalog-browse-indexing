# frozen_string_literal: true

require "sequel"

module AuthorityBrowse
  DB_PATH = ENV["AUTHORITY_BROWSE_DB"] || "authorities.sqlite3"

  # @return [Sequel::SQLite::Dataset]
  def self.db(file)
    @db ||= if IS_JRUBY
              require "jdbc/sqlite3"
              Sequel.connect("jdbc:sqlite://#{file}")
            else
              require "sqlite3"
              Sequel.connect("sqlite://#{file}")
            end
  end
end

