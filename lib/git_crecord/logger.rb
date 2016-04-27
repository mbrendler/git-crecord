require 'logger'

module GitCrecord
  LOGGER = Logger.new(File.new(File.join(ENV['HOME'], '.git-crecord.log'), 'w'))
  LOGGER.formatter = proc{ |_severity, _datetime, _progname, msg| "#{msg}\n" }
  LOGGER.level = Logger::INFO
end
