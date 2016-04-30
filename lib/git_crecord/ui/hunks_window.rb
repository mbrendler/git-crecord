require 'curses'
require_relative 'color'
require_relative 'help_window'
require_relative '../git'
require_relative '../quit_action'

module GitCrecord
  module UI
    class HunksWindow
      SELECTED_MAP = {true => 'X', false => ' ', :partly => '~'}.freeze

      def initialize(win, files)
        @win = win
        @files = files
        @visibles = @files
        @highlighted = @files[0]
        @scroll_position = 0

        resize
      end

      def getch
        @win.getch
      end

      def refresh
        @win.refresh(scroll_position, 0, 0, 0, Curses.lines - 1, @win.maxx)
      end

      def redraw
        @win.clear
        print_list(@files)
        refresh
      end

      def resize
        new_width = Curses.cols
        new_height = [Curses.lines, height(new_width)].max
        return if @win.maxx == new_width && @win.maxy == new_height
        @win.resize(new_height, new_width)
        redraw
      end

      def height(width, differences = @files)
        differences.reduce(@files.size) do |h, entry|
          h + \
            entry.strings(content_width(entry, width), large: true).size + \
            height(width, entry.subs)
        end
      end

      def content_width(entry, width = @win.maxx)
        width - entry.x_offset - 5
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
        print_entry(from, from.y1 - 1)
        print_entry(to, to.y1 - 1)
        refresh
      end

      def addstr(str, y = nil, x = 0, attr: 0, fill: false)
        @win.setpos(y, x) unless y.nil?
        @win.attrset(attr)
        @win.addstr(str)
        fill_size = @win.maxx - @win.curx
        return unless fill && fill_size > 0
        @win.addstr((fill * fill_size)[0..fill_size])
      end

      def print_list(list, line_number: -1)
        list.each do |entry|
          line_number = print_entry(entry, line_number)
          next unless entry.expanded
          line_number = print_list(entry.subs, line_number: line_number)
          addstr('', line_number += 1, fill: '_') if entry.is_a?(Diff::File)
        end
        line_number
      end

      def print_entry(entry, line_number)
        entry.y1 = line_number + 1
        prefix = "[#{SELECTED_MAP.fetch(entry.selected)}]  "
        attr = attrs(entry)
        prefix_attr = entry.is_a?(Diff::File) ? attr : 0
        entry.strings(content_width(entry)).each_with_index do |string, index|
          prefix = '     ' unless index == 0 && entry.selectable?
          addstr(prefix, line_number += 1, entry.x_offset, attr: prefix_attr)
          addstr(string, attr: attr, fill: ' ')
        end
        entry.y2 = line_number
      end

      def attrs(entry)
        color = Color.normal
        if entry.is_a?(Diff::Line)
          color = Color.green if entry.add?
          color = Color.red if entry.del?
        end
        color = Color.hl if entry == @highlighted
        color | (entry.is_a?(Diff::Line) ? 0 : Curses::A_BOLD)
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
        QuitAction.new{ Git.stage(@files) }
      end

      def commit
        QuitAction.new do
          Git.commit if Git.stage(@files) == true
        end
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
          @visibles[(index + 1)..-1].find{ |hunk| !hunk.subs.empty? }
        )
      end

      def highlight_previous_hunk
        index = @visibles.index(@highlighted)
        move_highlight(
          @visibles[0...index].reverse_each.find{ |hunk| !hunk.subs.empty? }
        )
      end

      def collapse
        return if @highlighted.subs.empty? || !@highlighted.expanded
        @highlighted.expanded = false
        update_visibles
        redraw
      end

      def expand
        return if @highlighted.subs.empty? || @highlighted.expanded
        @highlighted.expanded = true
        update_visibles
        @highlighted = @visibles[@visibles.index(@highlighted) + 1]
        redraw
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
        @files.each{ |file| file.selected = new_selected }
        redraw
      end

      def help_window
        HelpWindow.show
        refresh
      end
    end
  end
end
