# -*- encoding: utf-8 -*-
# stub: solr_cloud-connection 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "solr_cloud-connection".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/mlibrary/solr_cloud-connection/CHANGELOG.md", "homepage_uri" => "https://github.com/mlibrary/solr_cloud-connection", "source_code_uri" => "https://github.com/mlibrary/solr_cloud-connection" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2023-12-07"
  s.email = ["bill@dueber.com".freeze]
  s.homepage = "https://github.com/mlibrary/solr_cloud-connection".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Do basic administrative operations on a solr cloud instance and collections within".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.7.12"])
  s.add_runtime_dependency(%q<httpx>.freeze, ["~> 1.1.5"])
  s.add_runtime_dependency(%q<rubyzip>.freeze, ["~> 2.3.0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<dotenv>.freeze, [">= 0"])
  s.add_development_dependency(%q<standard>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
