require_relative 'lib/git_crecord/version'

GemSpec = Gem::Specification.new do |spec|
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.0.0'
  spec.name = 'git-crecord'
  spec.version = GitCrecord::VERSION
  spec.authors = 'Maik Brendler'
  spec.email = 'maik.brendler@invision.de'
  spec.summary = 'Git command to stage/commit hunks the simple way.'
  spec.description = %w(
    This gem adds the git-crecord command.
    It provides a curses UI to stage/commit git-hunks.
  ).join(' ')
  spec.license = 'MIT'
  spec.homepage = 'https://github.com/mbrendler/git-crecord'
  spec.metadata = {
    'issue_tracker' => 'https://github.com/mbrendler/git-crecord/issues',
    'allowed_push_host' => 'https://gems-eu.injixo.com'
  }
  spec.require_paths = %w(lib)
  spec.files = `git ls-files`.split($RS).delete_if{ |f| %r{^(spec|test)/} =~ f }
  spec.test_files = `git ls-files`.split($RS).grep(%r{^(spec|test)/})
  spec.executables = %w(git-crecord)
  spec.has_rdoc = false
  spec.extra_rdoc_files = %w(README.md CHANGELOG.md)
  spec.add_runtime_dependency 'curses', '~> 1.0', '>= 1.0.2'
  spec.add_development_dependency 'rake', '~> 10.1', '>= 10.1.1'
  spec.add_development_dependency 'minitest', '~> 5.8', '>= 5.8.4'
end
