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
    end
  end
end
