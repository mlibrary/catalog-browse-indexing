require_relative "generic_component"
require "forwardable"

module AuthorityBrowse
  module LocSKOSRDF

    class GenericEntry
      LOC_PREFIX = "http://id.loc.gov"

      extend Forwardable

      # Quick and dirty check to see if there are seeAlsos
      def self.has_see_also?(e)
        id = "#{LOC_PREFIX}#{e["@id"]}"
        e["@graph"].any?{|c| c["@id"] == id and c.has_key?("rdfs:seeAlso")}
      end


      # @return [Array<AuthorityBrowse::LocSKOSRDF::GenericSkosRDFGraphItem>] The graph items
      attr_reader :components, :count

      # @return [GenericSkosRDFGraphItem] The "main" component, whose id is the entry's id
      attr_accessor :main, :id

      def_delegators :@main, :type, :pref_label, :alt_labels

      def initialize(e, component_klass: AuthorityBrowse::LocSKOSRDF::GenericSkosRDFGraphItem)
        @count = 0
        @raw_id = e["@id"]
        @components = e["@graph"].map { |x| component_klass.new(x) }.each_with_object({}) { |item, h| h[item.id] = item }
        set_main!
        if @main.nil?
          # log an error
        end
      end

      def id
        @id ||= "#{LOC_PREFIX}#{@raw_id}"
      end

      def set_main!
        @main = @components[id]
      end

      # @return [Array<AuthorityBrowse::LocSKOSRDF::GenericSkosRDFGraphItem>] The graph items that are concepts
      def concepts
        @cpts ||= @components.select { |x| x.concept? }
      end

      # @return [Boolean] Whether or not this entry has any "see also" clauses
      def see_also?
        @main.has_key?("rdfs:seeAlso")
      end

    end
  end
end
