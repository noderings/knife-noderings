# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec) { |t| t.pattern = "spec/**/*_spec.rb" }
rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task(:spec) { abort "rspec is not installed. Run bundle install first." }
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  desc "Run Chefstyle"
  RuboCop::RakeTask.new(:style) { |t| t.options += ["--display-cop-names", "--no-color"] }
rescue LoadError
  puts "chefstyle is not installed. Run bundle install first."
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:docs)
rescue LoadError
  puts "yard is not available. Run bundle install first."
end

task default: %i{style spec}
