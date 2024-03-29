# frozen_string_literal: true

require_relative 'lib/git_crecord/version'

GemSpec = Gem::Specification.new do |spec|
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 3.0.0'
  spec.name = 'git-crecord'
  spec.version = GitCrecord::VERSION
  spec.authors = 'Maik Brendler'
  spec.email = 'maik.brendler@invision.de'
  spec.summary = 'Git command to stage/commit hunks the simple way.'
  spec.description = %w[
    This gem adds the git-crecord command.
    It provides a curses UI to stage/commit git-hunks.
  ].join(' ')
  spec.license = 'MIT'
  spec.homepage = 'https://github.com/mbrendler/git-crecord'
  spec.metadata = {
    'issue_tracker' => 'https://github.com/mbrendler/git-crecord/issues'
  }
  spec.require_paths = %w[lib]
  spec.files = `git ls-files`.split("\n").delete_if do |f|
    %r{^(spec|test)/} =~ f
  end
  spec.test_files = `git ls-files`.split("\n").grep(%r{^(spec|test)/})
  spec.executables = %w[git-crecord]
  spec.add_dependency 'curses'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '>= 0.56.0'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
end
