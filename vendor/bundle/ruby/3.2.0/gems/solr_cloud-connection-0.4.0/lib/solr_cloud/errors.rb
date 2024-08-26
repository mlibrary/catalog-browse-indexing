# frozen_string_literal: true

# Errors to make it more clear what's going on if things go south
module SolrCloud
  class NoSuchCollectionError < ArgumentError; end

  class NoSuchConfigSetError < ArgumentError; end

  class NoSuchAliasError < ArgumentError; end

  class WontOverwriteError < RuntimeError; end

  class ConfigSetInUseError < RuntimeError; end

  class CollectionAliasedError < RuntimeError; end

  class UnsupportedSolr < RuntimeError; end

  class Unauthorized < ArgumentError; end

  class ConnectionFailed < RuntimeError; end

  class IllegalNameError < ArgumentError; end
end
