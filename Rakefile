# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/git_crecord/**/*test.rb']
end

desc 'run system tests'
task :systemtest do
  sh(File.join(__dir__, 'test/system-test.sh'))
end

RuboCop::RakeTask.new

task default: %i[test systemtest rubocop]
