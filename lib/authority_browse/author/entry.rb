# frozen_string_literal: true

require "delegate"
require "json"
require "digest"

module AuthorityBrowse
  module Author
    class Entry < SimpleDelegator

      def initialize(author:, count: 0, alternate_forms: [], naf_id: nil, see_instead: nil)
        @data = Record.new(author: author, count: count, alternate_forms: alternate_forms, naf_id: naf_id)
        if see_instead
          @data = @data.to_redirect(see_instead: see_instead)
        end
        __setobj__(@data)
        yield self if block_given?
      end

      def self.from_naf_hash(naf_hash)
        e = self.new(author: naf_hash["author"], see_instead: naf_hash["see_instead"]) do |e|
          e.alternate_forms = naf_hash["alternate_forms"]
          e.naf_id = naf_hash["id"]
        end
        yield e if block_given?
        e
      end

      # If we add a see instead, or set it to nil, we want to convert the underlying
      # data object to the appropriate type
      # No one should have a pointer to that underlying structure anyway, so it shouldn't matter.
      # @param [String] new_si The new value for "see instead"
      # @return [String] the new see_instead value, or nil if it's nil
      def see_instead=(new_si)
        @data = if new_si.nil? || new_si.empty?
                  @data.to_record
                else
                  @data.to_redirect(see_instead: new_si)
                end
        __setobj__(@data)
        new_si
      end

      def is_record?
        record_type == "record"
      end

      def is_redirect?
        record_type == "redirect"
      end


      # Just hashify the json returned by the child object
      def to_json
        @data.to_h.to_json
      end
    end

    # @private
    class Record

      PARTS_JOINER = "!!"

      attr_accessor :author, :alternate_forms, :count, :naf_id

      # Given an author, create the appropriate object and then yield itself so
      # you can have block-assignments
      # @param [String] author The name to index
      # @param [Fixnum] count Number of occurrences in the catalog
      # @param [Array<String>] alternate_forms Other forms of this name
      # @yieldreturn [AuthorityBrowse::Author::Entry]
      def initialize(author:, count: 0, alternate_forms: [], naf_id: nil)
        @author = author
        @alternate_forms = []
        @count = count
        @naf_id = naf_id
        @record_type = "record"
        yield self if block_given?
      end

      # Browse field is always "author"
      def browse_field
        "author"
      end

      # Record type is always "record"
      def record_type
        "record"
      end

      # The id doesn't need to be sensible, only stable for sorting. We'll generate a hash of
      # the author (before solr compares without diacritics and such) to make sure
      # we get a unique value, and tack it onto the end of the actual value.
      #
      # Join with PARTS_JOINER because it's near the beginning of the ASCII chart so things will sort correctly
      def author_hash
        Digest::MD5.hexdigest(author)
      end

      def id
        [author, author_hash].join(PARTS_JOINER)
      end


      # Create a new redirect based on this record
      def to_redirect(see_instead:)
        Redirect.new(author: author, alternate_forms: alternate_forms,
                     count: count, naf_id: naf_id, see_instead: see_instead)
      end

      # Records don't have see_instead values
      def see_instead
        nil
      end

      def to_record
        self
      end

      def to_h
        {
          id: id,
          author: author,
          alternate_forms: alternate_forms,
          count: count,
          record_type: record_type,
          browse_field: browse_field,
          naf_id: naf_id
        }
      end
    end

    # @private
    class Redirect < Record
      attr_accessor :see_instead

      # @see Record::Initialize
      # Adds on a required parameter on where to redirect to
      # @param [String] see_instead The preferred name to redirect users to
      def initialize(see_instead:, **kwargs)
        super(**kwargs)
        @see_instead = see_instead
        yield self if block_given?
      end

      def to_redirect(see_instead: nil)
        see_instead = see_instead
        self
      end

      def to_record
        Record.new(author: author, alternate_forms: alternate_forms,
                   count: count, naf_id: naf_id)
      end

      # Record type is always "redierct"
      def record_type
        "redirect"
      end

      def to_h
        h = super
        h[:see_instead] = see_instead
        h
      end
    end
  end
end
