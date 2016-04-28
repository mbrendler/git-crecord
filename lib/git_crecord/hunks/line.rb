require_relative 'hunk_base'

module GitCrecord
  module Hunks
    class Line < HunkBase
      attr_accessor :y1, :y2
      attr_accessor :selected

      def initialize(line)
        @line = line
        @selected = true
        super(add? || del?)
      end

      def strings(width, **_)
        @line.scan(/.{1,#{width}}/)
      end

      def x_offset
        6
      end

      def add?
        @line.start_with?('+')
      end

      def del?
        @line.start_with?('-')
      end

      def highlightable?
        add? || del?
      end

      def expanded
        false
      end

      def generate_diff
        return " #{@line[1..-1]}" if !selected && del?
        return @line if selected
        nil
      end
    end
  end
end