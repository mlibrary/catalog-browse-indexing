# -*- encoding: utf-8 -*-
# stub: milemarker 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "milemarker".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/billdueber/milemarker/CHANGELOG.md", "homepage_uri" => "https://github.com/billdueber/milemarker", "source_code_uri" => "https://github.com/billdueber/milemarker" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-11-29"
  s.email = ["bill@dueber.com".freeze]
  s.homepage = "https://github.com/billdueber/milemarker".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Track and produce loglines for batch processing progress.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.7"])
end
