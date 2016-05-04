require_relative '../ui/color'

module GitCrecord
  module Diff
    class Difference
      attr_accessor :expanded
      attr_accessor :y1, :y2
      attr_reader :subs

      SELECTED_MAP = {
        true => '[X]  ',
        false => '[ ]  ',
        :partly => '[~]  '
      }.freeze
      SELECTION_MARKER_WIDTH = SELECTED_MAP[true].size

      def initialize
        @subs = []
      end

      def strings(width)
        to_s.scan(/.{1,#{content_width(width)}}/)
      end

      def max_height(width)
        width = content_width(width)
        ((to_s.size - 1).abs / width) + 1 + subs.reduce(0) do |a, e|
          a + e.max_height(width)
        end
      end

      def content_width(width)
        [1, width - x_offset - SELECTION_MARKER_WIDTH].max
      end

      def selectable?
        true
      end

      def selectable_subs
        @selectable_subs ||= subs.select(&:selectable?)
      end

      def selected
        s = selectable_subs.map(&:selected).uniq
        return s[0] if s.size == 1
        :partly
      end

      def selected=(value)
        selectable_subs.each{ |sub| sub.selected = value }
      end

      def style(_is_highlighted)
        UI::Color.normal
      end

      def prefix_style(_is_highlighted)
        UI::Color.normal
      end

      def print(win, line_number, is_highlighted)
        @y1 = line_number + 1
        prefix = SELECTED_MAP.fetch(selected)
        strings(win.width).each_with_index do |string, index|
          prefix = '     ' unless index == 0 && selectable?
          p_style = prefix_style(is_highlighted)
          win.addstr(' ' * x_offset, line_number += 1, attr: p_style)
          win.addstr(prefix, attr: p_style)
          win.addstr(string, attr: style(is_highlighted), fill: ' ')
        end
        @y2 = line_number
      end
    end
  end
end
