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
        e["@graph"].any? { |c| c["@id"] == id and c.has_key?("rdfs:seeAlso") }
      end

      # @return [Array<AuthorityBrowse::LocSKOSRDF::GenericSkosRDFGraphItem>] The graph items
      attr_reader :components

      # @return [Integer] the number of documents with this value as reported by solr
      # @return [String]
      attr_reader :id

      # @return [GenericSkosRDFGraphItem] The "main" component, whose id is the entry's id
      attr_accessor :main

      def_delegators :@main, :type, :pref_label, :alt_labels

      def initialize(e, component_klass: AuthorityBrowse::LocSKOSRDF::GenericSkosRDFGraphItem)
        @raw = e.dup
        @count = 0
        @raw_id = e["@id"]
        @components = e["@graph"].map { |x| component_klass.new(x) }.each_with_object({}) { |item, h| h[item.id] = item }
        @deprecated = @components.values.any? { |c| c.type == "cs:ChangeSet" and c.collect_scalar("cs:changeReason") == "deprecated" }
        set_main!
        if @main.nil?
          # log an error
        end
      end

      def id
        @id ||= "#{LOC_PREFIX}#{@raw_id}"
      end

      def base_id
        @base_id ||= id.split("/").last
      end

      def set_main!
        @main = @components[id]
      end

      def deprecated?
        @deprecated
      end

      def label
        main.label
      end

      def search_key
        AuthorityBrowse::Normalize.search_key(label)
      end

      def match_text
        AuthorityBrowse::Normalize.match_text(label)
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

#
# Zinzout.zout("aab_with_matching_ids.txt.gz") do |out|
#   aab = Zinzout.zin("aab.txt")
#   counts = {0 => 0, 1 => 0, :more => 0}
#   aab.each do |line|
#     fields = line.chomp.split(/\t/)
#     normalized = AuthorityBrowse::UnicodeNormalize.normalize(fields.first)
#     matches = ps.call(n: normalized)
#     case matches.size
#     when 1
#       counts[1] += 1
#     when 0
#       counts[0] += 1
#     else
#       counts[:more] += 1
#     end
#     ids = matches.map{|x| x[:id]}
#     fields << ids.join("|")
#     out.puts fields.join("\t")
#   end
# end
