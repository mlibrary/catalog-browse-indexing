# frozen_string_literal: true

require "sequel"
require "pathname"
require_relative "db/names"
require_relative "db/subjects"

module AuthorityBrowse
  def self.db
    Services[:database]
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

  class DB
    # Names and create code for the database.
    # Must be overridden with a hash like the return type
    # @return [Hash] Hash of tablename.to_sym => Proc.new { Sequel create code }
    def self.database_definitions
      $stderr.warn "Don't call AuthorityBrowse.database_definitions directly"
      exit(1)
    end

    def self.already_set_up?
      tables = Services[:database].tables
      database_definitions.keys.all? { |t| tables.include? t }
    end

    def self.recreate_table!(table)
      t = table.to_sym
      Services[:database].drop_table?(t)
      Services[:database].create_table(t, &database_definitions[t])
    end

    def self.recreate_all_tables!
      database_definitions.keys.each { |table| recreate_table!(table) }
    end

    def self.recreate_missing_tables!
      database_definitions.keys.each do |table|
        recreate_table!(table) unless S[:database].tables.include?(table)
      end
    end
  end
end
