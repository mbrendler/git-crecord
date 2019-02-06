# frozen_string_literal: true

require_relative 'lib/git_crecord/version'

GemSpec = Gem::Specification.new do |spec|
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.3.0'
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
  spec.files = `git ls-files`.split($RS).delete_if do |f|
    %r{^(spec|test)/} =~ f
  end
  spec.test_files = `git ls-files`.split($RS).grep(%r{^(spec|test)/})
  spec.executables = %w[git-crecord]
  spec.add_dependency 'curses', '~>1.0'
  spec.add_development_dependency 'minitest', '~> 5.8', '>= 5.8.4'
  spec.add_development_dependency 'rake', '~> 10.1', '>= 10.1.1'
  spec.add_development_dependency 'rubocop', '>= 0.56.0'
end
