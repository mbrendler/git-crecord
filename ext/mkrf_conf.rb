require 'rubygems'
require 'rubygems/dependency_installer'

# This is a hack to not install curses for ruby-2.0.

di = Gem::DependencyInstaller.new

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.1.0')
  puts 'install curses'
  di.install 'curses', '~>1.0'
end

File.open(File.join(__dir__, 'Rakefile'), 'w') do |f|
  f.write("task :default#{$/}")
end
