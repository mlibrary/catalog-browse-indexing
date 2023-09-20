module AuthorityBrowse
  module LocAuthorities
    # This is a Skos Entry
    class Entry

      # Turns a hash of a skos line into something that can be put into the
      # database 
      # @param data [Hash] [Hash version of a line of a skos file]
      def initialize(data)
        @data = data   
      end

      # @return [String] Skos Entry Id
      def id
        @id ||= "http://id.loc.gov#{@data["@id"]}"
      end

      # @return [String] Preferred Label
      def label
        main_component["skos:prefLabel"] 
      end

      
      # @return [Array] [Array of strings of see_also_ids] 
      def see_also_ids
        rdfs_seeAlso = main_component["rdfs:seeAlso"]
        return [] if rdfs_seeAlso.nil?
        if rdfs_seeAlso.class == Hash
          [rdfs_seeAlso["@id"]]
        else #it's an Array
          rdfs_seeAlso.map{|x| x["@id"] } 
        end
      end

      def main_component
        @main_component ||= @data["@graph"].find {|x| x["@id"] == id }
      end

      # Are there any seealso ids?
      # @return [Boolean] 
      def see_also_ids?
        !see_also_ids.empty?
      end

      # Writes to the names and names_see_also tables so that cross references
      # are properly set up
      def save_to_db
        Name.create(id: id, label: label) 
        if see_also_ids?
          see_also_ids.each do |see_also_id|
            DB[:names_see_also].insert(name_id: id, see_also_id: see_also_id)
          end
        end
      end
      
    end
  end
end
