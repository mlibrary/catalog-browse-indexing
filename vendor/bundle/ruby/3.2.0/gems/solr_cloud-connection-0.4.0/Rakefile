# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard docs]
task docs: %i[yard]

require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"] # optional
  t.options = [
    "-mmarkdown",
    "--embed-mixin", "SolrCloud::Connection::CollectionAdmin",
    "--embed-mixin", "SolrCloud::Connection::ConfigsetAdmin",
    "--embed-mixin", "SolrCloud::Connection::AliasAdmin",
    "--hide-void-return"
  ]
  # t.stats_options = ["--list-undoc"] # optional
end
