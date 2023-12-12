$LOAD_PATH.unshift(File.dirname(__FILE__))

require "thor"
require "authority_browse"
require "call_number_browse"

module Browse
  class CLI < Thor
    # :nocov:
    def self.exit_on_failure?
      true
    end
    # :nocov:

    class Solr < Thor
      desc "set_up_daily_authority_browse_collection", "sets up daily AuthorityBrowse collection"
      def set_up_daily_authority_browse_collection
        S.logger.info "Create configset #{AuthorityBrowse::Solr.configset_name} if needed"
        AuthorityBrowse::Solr.create_configset_if_needed
        S.logger.info "Setup daily collection: #{AuthorityBrowse::Solr.collection_name}"
        AuthorityBrowse::Solr.set_up_daily_collection
      end

      desc "verify_and_deploy_authority_browse_collection", "verifies that the reindex succeeded and if so updates the production alias"
      def verify_and_deploy_authority_browse_collection
        S.logger.info "Verifying Reindex"
        AuthorityBrowse::Solr.verify_reindex
        S.logger.info "Change production alias"
        AuthorityBrowse::Solr.set_production_alias
      end

      desc "list_authority_browse_collections_to_prune", "lists authority_browse collections that should be pruned"
      def list_authority_browse_collections_to_prune
        puts AuthorityBrowse::Solr.list_old_collections
      end

      desc "prune_authority_browse_collections", "prunes authority browse collections down to the latest 3 collections"
      def prune_authority_browse_collections
        AuthorityBrowse::Solr.prune_old_collections
      end
    end

    class CallNumbers < Thor
      desc "load_docs", "fetches and loads callnumber docs into solr"
      def load_docs
        CallNumberBrowse::TermFetcher.run
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
