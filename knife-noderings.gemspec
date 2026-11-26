# frozen_string_literal: true

require_relative "lib/knife-noderings/version"

Gem::Specification.new do |s|
  s.name = "knife-noderings"
  s.version = KnifeNoderings::VERSION
  s.authors = ["NodeRings"]
  s.email = ["partners@noderings.com"]
  s.homepage = "https://noderings.com"
  s.summary = "NodeRings support for Chef's knife: order, bootstrap and manage NodeRings servers"
  s.description = "A knife plugin that orders NodeRings virtual machines from the marketplace and bootstraps " \
                  "Chef Infra or Cinc on them, and lists, shows, powers and deletes them."
  s.license = "Apache-2.0"

  s.files = %w{LICENSE README.md CHANGELOG.md} + Dir.glob("lib/**/*.rb")
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.1"

  source_code = "https://github.com/noderings/knife-noderings"
  s.metadata = {
    "bug_tracker_uri" => "#{source_code}/issues",
    "changelog_uri" => "#{source_code}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{source_code}#readme",
    "homepage_uri" => s.homepage,
    "source_code_uri" => source_code,
    "rubygems_mfa_required" => "true",
  }

  # The plugin talks to the API with the Ruby standard library only.
  s.add_dependency "knife", ">= 18.0", "< 20"
end
