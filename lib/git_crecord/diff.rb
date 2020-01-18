# frozen_string_literal: true

require_relative 'diff/file'
require_relative 'git'

module GitCrecord
  module Diff
    def self.create(reverse: false, untracked: false)
      GitCrecord::Git.status.lines.map do |file_status|
        status = file_status[reverse ? 0 : 1].downcase
        filename = file_status.chomp[3..-1]
        next if status == ' ' || status == '?' && !untracked

        method = "handle_status_#{status}"
        send(method, filename, reverse: reverse) if respond_to?(method)
      end.compact
    end

    def self.handle_status_m(filename, reverse: false)
      filename, filename_b = filename.split(' -> ')
      filename = filename_b unless filename_b.nil?
      file = File.new(filename, filename, type: :modified, reverse: reverse)
      diff_lines = Git.diff(filename: filename, staged: reverse).lines[4..-1]
      diff_lines.each do |line|
        handle_line(file, line)
      end
      file
    end

    def self.handle_status_a(filename, reverse: false)
      file = File.new(filename, filename, type: :new, reverse: reverse)
      diff_lines = Git.diff(filename: filename, staged: reverse).lines[5..-1]
      file.make_empty if diff_lines.nil?
      (diff_lines || []).each do |line|
        handle_line(file, line)
      end
      file
    end

    def self.handle_status_?(filename, **_)
      File.new(filename, filename, type: :untracked).tap do |file|
        lines, err = file_lines(filename)
        if lines.empty?
          file.make_empty(err)
        else
          file << "@@ -0,0 +1,#{lines.size} @@"
          lines.each { |line| file.add_hunk_line("+#{line.chomp}") }
        end
        file.selected = false
      end
    end

    # o   ' ' = unmodified
    # o   M = modified
    # o   A = added
    # o   D = deleted
    # o   R = renamed
    # o   C = copied
    # o   U = updated but unmerged

    def self.handle_line(file, line)
      line.chomp!
      if hunk_start?(line)
        file << line
      else
        file.add_hunk_line(line)
      end
    end

    def self.hunk_start?(line)
      line.start_with?('@@')
    end

    def self.file_encoding(filename)
      `file --mime-encoding #{filename}`.split(': ', 2)[1].chomp
    end

    def self.file_lines(filename)
      return [[], 'empty'] if ::File.size(filename).zero?

      encoding = file_encoding(filename)
      return [[], 'binary'] if encoding == 'binary'

      [::File.open(filename, "r:#{encoding}", &:readlines), nil]
    end
  end
end
