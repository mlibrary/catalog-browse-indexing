require "authority_browse/loc_skos/name/entry"

module AuthorityBrowse
  module LocSKOSRDF
    module Name
      class Skosfile

        include Enumerable

        def initialize(skosfile)
          @skosfile = skosfile
        end

        #@yieldreturn [Event] Each event, in turn, from the skosrdf file
        def each
          Zinzout.zin(@skosfile).each { |eline| yield Entry.new_from_skosline(eline) }
        end
      end
    end
  end
end