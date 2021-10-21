# frozen_string_literal: true

require 'rake'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'run system tests'
task :systemtest do
  sh(File.join(__dir__, 'system-test.sh'))
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec systemtest rubocop]
