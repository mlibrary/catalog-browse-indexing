$LOAD_PATH.unshift(File.dirname(__FILE__))

require "thor"
require "authority_browse"

module Browse
  class CLI < Thor
    desc "all", "runs everything"
    long_desc <<~DESC
      For now this runs everything for the names daily update
    DESC
    def all
      # TODO:
      # Create date
      # Get git version
      # If no git version then get shortend version of commit hash
      # See below:
      # if msg=`git describe --exact-match --tags @ 2>&1`; then
      #     echo $msg;
      #  else
      #    git rev-parse --short HEAD
      #  fi
      #
      #
      # Make a new configset if the version changed. Otherwise don't?
      # Make a new collection with tag and date
      # Set reindex alias
      S.info "Start update"
      AuthorityBrowse::Names.update
      S.info "Start loading matched"
      AuthorityBrowse::Names.load_solr_with_matched
      S.info "Start loading unmatched"
      AuthorityBrowse::Names.load_solr_with_unmatched
      # TODO:
      # Check numbers in solr
      # Check staging/qa/whatever version of front-end that reads from reindex
      # Change the alias
      # Error at any point, ALERT somehow
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
