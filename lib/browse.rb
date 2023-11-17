$LOAD_PATH.unshift(File.dirname(__FILE__))

require "thor"
require "authority_browse"

module Browse
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "all", "runs everything"
    long_desc <<~DESC
      For now this runs everything for the names daily update
    DESC
    def all
      S.logger.info "Create configset #{AuthorityBrowse::Solr.configset_name} if needed"
      AuthorityBrowse::Solr.create_configset_if_needed
      S.logger.info "Setup daily collection: #{AuthorityBrowse::Solr.collection_name}"
      AuthorityBrowse::Solr.setup_daily_collection
      S.logger.info "Start update"
      AuthorityBrowse::Names.update
      S.logger.info "Start loading matched"
      AuthorityBrowse::Names.load_solr_with_matched
      S.logger.info "Start loading unmatched"
      AuthorityBrowse::Names.load_solr_with_unmatched
      S.logger.info "Verifying Reindex"
      AuthorityBrowse::Solr.verify_reindex
      S.logger.info "Change production alias"
      AuthorityBrowse::Solr.set_production_alias
    end

    desc "set_up_daily_authority_browse_collection", "sets up daily AuthorityBrowse collection"
    def set_up_daily_authority_browse_collection
      S.logger.info "Create configset #{AuthorityBrowse::Solr.configset_name} if needed"
      AuthorityBrowse::Solr.create_configset_if_needed
      S.logger.info "Setup daily collection: #{AuthorityBrowse::Solr.collection_name}"
      AuthorityBrowse::Solr.setup_daily_collection
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
      AuthorityBrowse::Solr.get_collections_to_delete
    end

    desc "prune_authority_browse_collections", "prunes authority browse collections down to the latest 3 collections"
    def prune_authority_browse_collections
      AuthorityBrowse::Solr.clean_old_collections
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

    desc "names SUBCOMMAND", "commands related to author browse"
    subcommand "names", Names
  end
end
