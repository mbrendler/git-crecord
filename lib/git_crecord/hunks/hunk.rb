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

      def strings(width)
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

      def generate_diff(out_line_offset = 0)
        return [nil, out_line_offset] unless selected
        header, out_line_offset = generate_header(out_line_offset)
        content = [
          header,
          *subs.map(&:generate_diff).compact
        ].join("\n")
        [content, out_line_offset]
      end

      def generate_header(out_line_offset)
        old_start, old_count, new_start, new_count = @head.match(
          /@@ -(\d+),(\d+) \+(\d+),(\d+) @@/
        )[1..4].map(&:to_i)
        new_start += out_line_offset
        highlightable_subs.each do |sub|
          next if sub.selected
          new_count -= 1 if sub.add?
          new_count += 1 if sub.del?
        end
        [
          "@@ -#{old_start},#{old_count} +#{new_start},#{new_count} @@",
          new_start + new_count
        ]
      end
    end
  end
end
