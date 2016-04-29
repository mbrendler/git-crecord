require_relative 'hunk_base'
require_relative 'line'

module GitCrecord
  module Hunks
    class Hunk < HunkBase
      attr_accessor :y1, :y2

      def initialize(head)
        @head = head
        @lines = []
        @expanded = true
        super()
      end

      def strings(width, **_)
        @head.scan(/.{1,#{width}}/)
      end

      def x_offset
        3
      end

      def <<(line)
        @lines << Line.new(line)
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
        match = @head.match(/@@ -(\d+)(,(\d+))? \+(\d+)(,(\d+))? @@/)
        [match[1], match[3] || 1, match[4], match[6] || 1].map(&:to_i)
      end
    end
  end
end
