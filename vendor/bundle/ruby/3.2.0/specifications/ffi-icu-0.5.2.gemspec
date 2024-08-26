# -*- encoding: utf-8 -*-
# stub: ffi-icu 0.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ffi-icu".freeze
  s.version = "0.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jari Bakken".freeze]
  s.date = "2019-10-15"
  s.description = "Provides charset detection, locale sensitive collation and more. Depends on libicu.".freeze
  s.email = "jari.bakken@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/jarib/ffi-icu".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Simple Ruby FFI wrappers for things I need from ICU.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.0", ">= 1.0.9"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
end
