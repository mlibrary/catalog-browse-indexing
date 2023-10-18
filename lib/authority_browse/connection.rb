# frozen_string_literal: true

require "delegate"
require "faraday"
require "httpx/adapters/faraday"

module AuthorityBrowse
  # Deprecated TBDeleted
  class Connection < SimpleDelegator
    attr_reader :conn
    # A basic solr connection with url encoding and json handling
    def initialize
      @conn = HTTPX.with(timeout: {connect_timeout: 60})
      __setobj__(@conn)
      yield self if block_given?
    end
  end
end
