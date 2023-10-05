# frozen_string_literal: true

require "sequel"
require "pathname"
require "services"

module AuthorityBrowse
  module DB

    # Names and create code for the database.
    # Must be overridden with a hash like the return type
    # @return [Hash] Hash of tablename.to_sym => Proc.new { Sequel create code }
    def database_definitions
      $stderr.warn "Don't call AuthorityBrowse.database_definitions directly"
      exit(1)
    end

    def db
      Services[:database]
    end

    def self.db
      Services[:database]
    end
    
    def self.switch_to_persistent_sqlite(db_file)
      Services.register(:test_database_file) { db_file }
      Services.register(:database) { Services[:test_database_persistent] }
      Services[:database]
    end

    def already_set_up?
      tables = Services[:database].tables
      database_definitions.keys.all? { |t| tables.include? t }
    end

    def recreate_table!(table)
      t = table.to_sym
      Services[:database].drop_table?(t)
      Services[:database].create_table(t, &database_definitions[t])
    end

    def recreate_all_tables!
      database_definitions.keys.each { |table| recreate_table!(table) }
    end
  end
end
