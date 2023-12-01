# frozen_string_literal: true

require "milemarker"
require "logger"
require "byebug"
require "services"
require "concurrent"

module AuthorityBrowse
  # Fetches the names skos file from the library of congress. Puts it in the
  # tmp directory. This is a pain to test so that's why it's been extracted.
  # To try it you can run this method and put in a different url and make
  # sure it gets approriately downloaded.
  #
  # @param url [String] [location skos file for names]
  def self.fetch_skos_file(remote_file:, local_file:)
    conn = Faraday.new do |builder|
      builder.use Faraday::Response::RaiseError
      builder.response :follow_redirects
      builder.adapter :httpx
    end
    File.open(local_file, "w") do |f|
      resp = conn.get(remote_file) do |req|
        req.options.on_data = proc do |chunk, _overall_received_bytes, _env|
          f << chunk
        end
      end
      puts resp
    end
  end

  module Name
    class << self
      def name
        :name
      end

      def xrefs
        [
          OpenStruct.new(
            name: :see_also,
            count_key: :see_also_count,
            label_key: :see_also_label
          )
        ]
      end
    end
  end

  module Subject
    class << self
      def name
        :subject
      end

      def xrefs
        [
          OpenStruct.new(
            name: :broader,
            count_key: :broader_count,
            label_key: :broader_label
          ),
          OpenStruct.new(
            name: :narrower,
            count_key: :narrower_count,
            label_key: :narrower_label
          )
        ]
      end
    end
  end
end

require "authority_browse/loc_authorities"
require "authority_browse/loc_skos"
require "authority_browse/db"
require "authority_browse/db_mutator"
require "authority_browse/term_fetcher"
require "authority_browse/normalize"
require "authority_browse/loc_skos/unmatched_entry"
require "authority_browse/solr"
require "authority_browse/solr/uploader"
require "authority_browse/solr_document"
require "authority_browse/names"
require "authority_browse/subjects"
