require_relative 'difference'
require_relative 'hunk'

module GitCrecord
  module Diff
    class File < Difference
      attr_reader :filename_a
      attr_reader :type

      def initialize(filename_a, filename_b, type: :modified)
        @filename_a = filename_a
        @filename_b = filename_b
        @type = type
        @hunks = []
        @expanded = false
      end

      def to_s
        prefix = {modified: 'M', untracked: '?'}.fetch(type)
        return "#{prefix} #{@filename_a}" if @filename_a == @filename_b
        "#{prefix} #{filename_a} -> #{filename_b}"
      end

      def info_string
        line_count = subs.reduce(0){ |a, e| e.selectable_subs.size + a }
        "  #{subs.size} hunk(s), #{line_count} line(s) changed"
      end

      def strings(width, large: expanded)
        result = to_s.scan(/.{1,#{width}}/)
        return result unless large
        result += info_string.scan(/.{1,#{width}}/)
        result << ''
      end

      def x_offset
        0
      end

      def <<(hunk)
        @hunks << Hunk.new(hunk)
        self
      end

      def add_hunk_line(line)
        @hunks.last << line
      end

      def subs
        @hunks
      end

      def generate_diff
        return unless selected
        [
          "diff --git a/#{@filename_a} b/#{@filename_b}",
          "--- a/#{@filename_a}",
          "+++ b/#{@filename_b}",
          *subs.map(&:generate_diff).compact,
          ''
        ].join("\n")
      end
    end
  end
end
