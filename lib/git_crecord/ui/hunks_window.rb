# frozen_string_literal: true

require 'forwardable'
require 'curses'
require_relative 'color'
require_relative 'help_window'
require_relative '../git'
require_relative '../quit_action'

module GitCrecord
  module UI
    class HunksWindow
      extend Forwardable

      def initialize(win, files)
        @win = win
        @files = files
        @visibles = @files
        @highlighted = @files[0]
        @scroll_position = 0

        resize
      end

      delegate getch: :@win
      def_delegator :@win, :maxx, :width

      def highlight_position
        "#{@visibles.index(@highlighted) + 1}/#{@visibles.size}"
      end

      def refresh
        @win.refresh(scroll_position, 0, 0, 0, Curses.lines - 1, width)
      end

      def redraw
        @win.clear
        print_list(@files)
        refresh
      end

      def resize
        new_width = Curses.cols
        new_height = [Curses.lines, content_height(new_width)].max
        return if width == new_width && @win.maxy == new_height

        @win.resize(new_height, new_width)
        redraw
      end

      def content_height(width)
        @files.reduce(@files.size) { |a, e| a + e.max_height(width) }
      end

      def scroll_position
        upper_position = @highlighted.y1 - 3
        if @scroll_position > upper_position
          @scroll_position = upper_position
        elsif @scroll_position <= @highlighted.y2 + 4 - Curses.lines
          @scroll_position = [@highlighted.y2 + 4, @win.maxy].min - Curses.lines
        end
        @scroll_position
      end

      def move_highlight(to)
        return if to == @highlighted || to.nil?

        from = @highlighted
        @highlighted = to
        from.print(self, from.y1 - 1, false)
        to.print(self, to.y1 - 1, true)
        refresh
      end

      def addstr(str, y_pos = nil, x_pos = 0, attr: 0, fill: false)
        @win.setpos(y_pos, x_pos) unless y_pos.nil?
        @win.attrset(attr)
        @win.addstr(str)
        fill_size = width - @win.curx
        return unless fill && fill_size.positive?

        @win.addstr((fill * fill_size)[0..fill_size])
      end

      def print_list(list, line_number = -1)
        list.each do |entry|
          line_number = entry.print(self, line_number, entry == @highlighted)
          next unless entry.expanded

          line_number = print_list(entry.subs, line_number)
          addstr('', line_number += 1, fill: '_') if entry.is_a?(Diff::File)
        end
        line_number
      end

      def update_visibles
        @visibles = @files.each_with_object([]) do |entry, vs|
          vs << entry
          next unless entry.expanded

          entry.selectable_subs.each do |entryy|
            vs << entryy
            vs.concat(entryy.selectable_subs) if entryy.expanded
          end
        end
      end

      def quit
        :quit
      end

      def stage
        QuitAction.new { |reverse| Git.stage(@files, reverse) }
      end

      def commit
        QuitAction.new { |reverse| Git.stage(@files, reverse) && Git.commit }
      end

      def highlight_next
        move_highlight(@visibles[@visibles.index(@highlighted) + 1])
      end

      def highlight_previous
        move_highlight(@visibles[[@visibles.index(@highlighted) - 1, 0].max])
      end

      def highlight_first
        move_highlight(@visibles[0])
      end

      def highlight_last
        move_highlight(@visibles[-1])
      end

      def highlight_next_hunk
        index = @visibles.index(@highlighted)
        move_highlight(
          @visibles[(index + 1)..-1].find { |entry| !entry.subs.empty? }
        )
      end

      def highlight_previous_hunk
        index = @visibles.index(@highlighted)
        move_highlight(
          @visibles[0...index].reverse_each.find { |entry| !entry.subs.empty? }
        )
      end

      def collapse
        toggle_fold if !@highlighted.subs.empty? && @highlighted.expanded
      end

      def expand
        toggle_fold if !@highlighted.subs.empty? && !@highlighted.expanded
      end

      def toggle_fold
        @highlighted.expanded = !@highlighted.expanded
        update_visibles
        redraw
      end

      def toggle_selection
        @highlighted.selected = !@highlighted.selected
        redraw
      end

      def toggle_all_selections
        new_selected = @files[0].selected == false
        @files.each { |file| file.selected = new_selected }
        redraw
      end

      def help_window
        HelpWindow.show
        refresh
      end
    end
  end
end
