# frozen_string_literal: true

require "sequel"
require "pathname"

module AuthorityBrowse
  DB_PATH = ENV["AUTHORITY_BROWSE_DB"] || "authorities.sqlite3"

  # @return [Sequel::SQLite::Dataset]
  def self.db(file)
    path = Pathname.new(file).realpath.to_s
    @db ||= if IS_JRUBY
              require "jdbc/sqlite3"
              Sequel.connect("jdbc:sqlite://#{path}")
            else
              require "sqlite3"
              Sequel.connect("sqlite://#{path}")
            end
  end
end

