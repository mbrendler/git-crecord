# frozen_string_literal: true

require_relative 'difference'
require_relative '../ui/color'

module GitCrecord
  module Diff
    class PseudoLine < Difference
      def initialize(line)
        @line = line || 'file is empty'
        super()
        @selected = false
      end

      def to_s
        @line
      end

      def x_offset
        6
      end

      def selectable?
        false
      end

      def expanded
        false
      end

      def generate_diff
        nil
      end

      def style(is_highlighted)
        Curses::A_BOLD | (is_highlighted ? UI::Color.hl : UI::Color.normal)
      end
    end

    class Line < Difference
      def initialize(line, reverse: false)
        @line = line
        super(reverse: reverse)
      end

      def to_s
        @to_s ||= @line.gsub(/\t/, Git.tab)
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

      def selectable?
        add? || del?
      end

      def selected=(value)
        @selected = selectable? ? value : selected
      end

      def expanded
        false
      end

      def generate_diff
        return " #{@line[1..]}" if !selected && del?
        return @line if selected

        nil
      end

      def style(is_highlighted)
        return UI::Color.hl if is_highlighted
        return UI::Color.green if add?
        return UI::Color.red if del?

        UI::Color.normal
      end
    end
  end
end
