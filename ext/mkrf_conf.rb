require 'rubygems'
require 'rubygems/dependency_installer'

# This is a hack to not install curses for ruby-2.0.

di = Gem::DependencyInstaller.new

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.1.0')
  di.install 'curses', '~>1.0'
end
