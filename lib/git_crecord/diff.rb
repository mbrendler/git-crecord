# frozen_string_literal: true

require_relative 'diff/file'

module GitCrecord
  module Diff
    def self.parse(diff)
      files = []
      enum = diff.lines.each
      loop do
        line = enum.next
        line.chomp!
        next files << parse_file_header(line, enum) if file_start?(line)
        next files[-1] << line if hunk_start?(line)
        files[-1].add_hunk_line(line)
      end
      files
    end

    def self.file_start?(line)
      line.start_with?('diff')
    end

    def self.hunk_start?(line)
      line.start_with?('@@')
    end

    def self.parse_file_header(line, enum)
      enum.next # index ...
      enum.next # --- ...
      enum.next # +++ ...
      File.new(*parse_filenames(line))
    end

    def self.parse_filenames(line)
      line.match(%r{a/(.*) b/(.*)$})[1..2]
    end

    def self.untracked_files(git_status)
      git_status.lines.select { |l| l.start_with?('??') }.flat_map do |path|
        path = path.chomp[3..-1]
        ::File.directory?(path) ? untracked_dir(path) : untracked_file(path)
      end.compact
    end

    def self.untracked_file(filename)
      File.new(filename, filename, type: :untracked).tap do |file|
        lines, err = file_lines(filename)
        file << "@@ -0,0 +1,#{lines.size} @@"
        file.subs[0].subs << PseudoLine.new(err) if lines.empty?
        lines.each { |line| file.add_hunk_line("+#{line.chomp}") }
        file.selected = false
      end
    end

    def self.untracked_dir(path)
      Dir.glob(::File.join(path, '**/*')).map do |filename|
        untracked_file(filename) unless ::File.directory?(filename)
      end
    end

    def self.file_encoding(filename)
      `file --mime-encoding #{filename}`.split(': ', 2)[1].chomp
    end

    def self.file_lines(filename)
      encoding = file_encoding(filename)
      return [[], 'binary'] if encoding == 'binary'
      [::File.open(filename, "r:#{encoding}", &:readlines), nil]
    end
  end
end
