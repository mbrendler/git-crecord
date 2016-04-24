require_relative 'hunks/file'

module GitCrecord
  module Hunks
    module_function

    def parse(diff)
      files = []
      diff.lines.each do |line|
        line.chomp!
        next files[-1].add_extra_line(line) if line.start_with?(*%w(index --- +++))
        next files << File.new(*parse_filenames(line)) if file_start?(line)
        next files[-1] << line if hunk_start?(line)
        files[-1].add_hunk_line(line)
      end
      files
    end

    def file_start?(line)
      line.start_with?('diff')
    end

    def hunk_start?(line)
      line.start_with?('@@')
    end

    def parse_filenames(line)
      line.match(%r{a/(.*) b/(.*)$})[1..2]
    end
  end
end
