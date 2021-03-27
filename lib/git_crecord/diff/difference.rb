# frozen_string_literal: true

require_relative '../ui/color'

module GitCrecord
  module Diff
    class Difference
      attr_accessor :expanded, :y1, :y2
      attr_reader :subs

      SELECTED_MAP = {
        true => '[X]  ',
        false => '[ ]  ',
        :partly => '[~]  '
      }.freeze

      REVERSE_SELECTED_MAP = {
        true => '[R]  ',
        false => '[X]  ',
        :partly => '[~]  '
      }.freeze

      SELECTION_MARKER_WIDTH = SELECTED_MAP[true].size

      def initialize(reverse: false)
        @reverse = reverse
        @selection_marker_map = reverse ? REVERSE_SELECTED_MAP : SELECTED_MAP
        @subs = []
        @selected = true
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
        return @selected if selectable_subs.empty?

        s = selectable_subs.map(&:selected).uniq
        return s[0] if s.size == 1

        :partly
      end

      def selected=(value)
        if selectable_subs.empty?
          @selected = value
        else
          selectable_subs.each { |sub| sub.selected = value }
        end
      end

      def style(is_highlighted)
        return Curses::A_BOLD | UI::Color.hl if is_highlighted

        Curses::A_BOLD | UI::Color.normal
      end

      def prefix_style(_is_highlighted)
        UI::Color.normal
      end

      def prefix(line_number)
        show_selection_marker = line_number.zero? && selectable?
        return @selection_marker_map.fetch(selected) if show_selection_marker

        ' ' * SELECTION_MARKER_WIDTH
      end

      def print(win, line_number, is_highlighted)
        @y1 = line_number + 1
        prefix_style = prefix_style(is_highlighted)
        style = style(is_highlighted)
        strings(win.width).each_with_index do |string, index|
          win.addstr(' ' * x_offset, line_number += 1, attr: prefix_style)
          win.addstr(prefix(index), attr: prefix_style)
          win.addstr(string, attr: style, fill: ' ')
        end
        @y2 = line_number
      end
    end
  end
end
