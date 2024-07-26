$LOAD_PATH.unshift(File.dirname(__FILE__))

require "thor"
require "authority_browse"
require "call_number_browse"
require "solr"

module Browse
  class CLI < Thor
    # :nocov:
    def self.exit_on_failure?
      true
    end
    # :nocov:

    class Solr < Thor
      ["authority_browse", "call_number_browse"].each do |kind|
        desc "set_up_daily_#{kind}_collection", "sets up daily #{kind} collection"
        define_method :"set_up_daily_#{kind}_collection" do
          manager = ::Solr::Manager.for(kind)
          S.logger.info "Create configset #{manager.configset_name} if needed"
          manager.create_configset_if_needed
          S.logger.info "Setup daily collection: #{manager.daily_name}"
          manager.set_up_daily_collection
        end

        desc "verify_and_deploy_#{kind}_collection", "verifies that the reindex succeeded and if so updates the production alias"
        define_method :"verify_and_deploy_#{kind}_collection" do
          manager = ::Solr::Manager.for(kind)
          S.logger.info "Verifying Reindex"
          manager.verify_reindex
          S.logger.info "Change production alias"
          manager.set_production_alias
        end

        desc "list_#{kind}_collections_to_prune", "lists #{kind} collections that should be pruned. Default is last three"
        option :keep, type: :numeric, default: 3
        define_method :"list_#{kind}_collections_to_prune" do
          manager = ::Solr::Manager.for(kind)
          puts manager.list_old_collections(keep: options[:keep])
        end

        desc "prune_authority_browse_collections", "prunes authority browse collections down to the latest N collections. Default is 3"
        option :keep, type: :numeric, default: 3
        define_method :"prune_#{kind}_collections" do
          manager = ::Solr::Manager.for(kind)
          manager.prune_old_collections(keep: options[:keep])
        end
      end
    end

    class CallNumbers < Thor
      desc "load_docs", "fetches and loads callnumber docs into solr"
      def load_docs
        CallNumberBrowse::TermFetcher.new.run
        ::Solr::Uploader.new(collection: "call_number_browse_reindex").send_file_to_solr(S.solr_docs_file)
      end
    end

    class Names < Thor
      desc "reset_db", "resets names skos tables"
      long_desc <<~DESC
        Downloads the latest version of the skosrdf data for names from the
        Library of Congress. Reloads the tables :names and :names_see_also with
        the new data. Gets rid of duplicate deprecated names.
      DESC
      def reset_db
        AuthorityBrowse::Names.reset_db
      end

      desc "update", "updates names tables with counts from biblio"
      long_desc <<~DESC
        Fetches author facet from biblio, resets and loads :names_from_biblio,
        resets counts in :names, puts :names_from_biblio counts into :names,
        and then puts ids from names into :names_from_biblio
      DESC
      def update
        AuthorityBrowse::Names.update
      end

      desc "load_solr_with_matched", "loads authority_browse solr collection with docs derrived from :names"
      long_desc <<~DESC
        Assuming that the :names is updated with counts, this generates solr
        documents and then uploads them to the authority_browse solr
        collection.
      DESC
      def load_solr_with_matched
        AuthorityBrowse::Names.load_solr_with_matched
      end

      desc "load_solr_with_unmatched", "loads authority_browse solr collection with docs derrived from :names_from_biblio"
      long_desc <<~DESC
        Assuming that the :names_from_biblio table is updated with ids from
        names, this generates solr documents for terms that don't have a
        name_id and then uploads them to the authority_browse solr collection.
      DESC
      def load_solr_with_unmatched
        AuthorityBrowse::Names.load_solr_with_unmatched
      end
    end

    class Subjects < Thor
      desc "reset_db", "resets subjects skos tables"
      long_desc <<~DESC
        Downloads the latest version of the skosrdf data for subjects from the
        Library of Congress. Reloads the tables :subjects and :names_see_also with
        the new data. Gets rid of duplicate deprecated subjects.
      DESC
      def reset_db
        AuthorityBrowse::Subjects.reset_db
      end

      desc "update", "updates subjects tables with counts from biblio"
      long_desc <<~DESC
        Fetches subject facet from biblio, resets and loads :subjects_from_biblio,
        resets counts in :subjects, puts :subjects_from_biblio counts into :subjects,
        and then puts ids from subjects into :subjects_from_biblio
      DESC
      def update
        AuthorityBrowse::Subjects.update
      end

      desc "load_solr_with_matched", "loads authority_browse solr collection with docs derrived from :subjects"
      long_desc <<~DESC
        Assuming that the :subjects is updated with counts, this generates solr
        documents and then uploads them to the authority_browse solr
        collection.
      DESC
      def load_solr_with_matched
        AuthorityBrowse::Subjects.load_solr_with_matched
      end

      desc "load_solr_with_unmatched", "loads authority_browse solr collection with docs derrived from :subjects_from_biblio"
      long_desc <<~DESC
        Assuming that the :subjects_from_biblio table is updated with ids from
        subjects, this generates solr documents for terms that don't have a
        name_id and then uploads them to the authority_browse solr collection.
      DESC
      def load_solr_with_unmatched
        AuthorityBrowse::Subjects.load_solr_with_unmatched
      end
      desc "generate_remediated_authorities_file", "generates a new file with the remediation rules for authority records"
      long_desc <<~DESC
        Gets and writes the authority records from Alma that have the rules for
        updating subject headings. The file is written to #{S.remediated_subjects_file}.
      DESC
      def generate_remediated_authorities_file
        AuthorityBrowse::Subjects.generate_remediated_authorities_file
      end
    end

    desc "solr SUBCOMMAND", "commands related to working with SolrCloud"
    subcommand "solr", Solr

    desc "names SUBCOMMAND", "commands related to author browse"
    subcommand "names", Names

    desc "subjects SUBCOMMAND", "commands related to subject browse"
    subcommand "subjects", Subjects

    desc "call_numbers SUBCOMMAND", "commands related to call number browse"
    subcommand "call_numbers", CallNumbers
  end
end
