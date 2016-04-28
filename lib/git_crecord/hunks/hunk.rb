require_relative 'hunk_base'
require_relative 'hunk_line'

module GitCrecord
  module Hunks
    class Hunk < HunkBase
      def initialize(head)
        @head = head
        @lines = []
        @expanded = true
        super()
      end

      def strings(width, **_)
        @head.scan(/.{1,#{width}}/)
      end

      def <<(line)
        @lines << HunkLine.new(line)
      end

      def subs
        @lines
      end

      def highlightable_subs
        @highlightable_subs ||= @lines.select(&:highlightable?)
      end

      def generate_diff
        return nil unless selected
        [generate_header, *subs.map(&:generate_diff).compact].join("\n")
      end

      def generate_header
        old_start, old_count, new_start, new_count = parse_header
        highlightable_subs.each do |sub|
          next if sub.selected
          new_count -= 1 if sub.add?
          new_count += 1 if sub.del?
        end
        "@@ -#{old_start},#{old_count} +#{new_start},#{new_count} @@"
      end

      def parse_header
        (
          @head.match(/@@ -(\d+),(\d+) \+(\d+),(\d+) @@/) ||
          @head.match(/@@ -(\d+),(\d+) \+(\d+) @@/).to_a + [1]
        )[1..4].map(&:to_i)
      end
    end
  end
end
