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
        @win.refresh(scroll_position, 0, 0, 0, Curses.lines - 1, @width)
      end

      def redraw
        @win.clear
        @win.resize(@height, @width)
        print_list(@files)
        refresh
      end

      def resize
        new_width = Curses.cols
        new_height = [Curses.lines, height(new_width)].max
        return if @width == new_width && @height == new_height
        @width = new_width
        @height = new_height
        redraw
      end

      def height(width, hunks = @files)
        hunks.reduce(0) do |h, entry|
          h + \
            entry.strings(width - entry.x_offset - 5, large: true).size + \
            height(width, entry.subs)
        end
      end

      def scroll_position
        if @scroll_position + 3 > @highlighted.y1
          @scroll_position = @highlighted.y1 - 3
        elsif @scroll_position - 4 + Curses.lines <= @highlighted.y2
          @scroll_position = [@highlighted.y2 + 4, @height].min - Curses.lines
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

      def print_list(list, line_number: -1)
        list.each do |entry|
          line_number = print_entry(entry, line_number)
          next unless entry.expanded
          line_number = print_list(entry.subs, line_number: line_number)
        end
        line_number
      end

      def print_entry(entry, line_number)
        is_highlighted = entry == @highlighted
        entry.y1 = line_number + 1
        entry.strings(@width - entry.x_offset - 5).each_with_index do |string, index|
          @win.attrset(entry.is_a?(Hunks::File) && is_highlighted ? attrs(entry) : 0)
          @win.setpos(line_number += 1, entry.x_offset)
          if index == 0 && entry.selectable
            @win.addstr("[#{SELECTED_MAP.fetch(entry.selected)}]  ")
          else
            @win.addstr('     ')
          end
          @win.attrset(attrs(entry))
          @win.addstr(string)
          add_spaces = (@width - entry.x_offset - 5 - string.size)
          @win.addstr(' ' * add_spaces) if add_spaces > 0
        end
        entry.y2 = line_number
      end

      def attrs(entry)
        color = Color.normal
        if entry.is_a?(Hunks::Line)
          color = Color.green if entry.add?
          color = Color.red if entry.del?
        end
        color = Color.hl if entry == @highlighted
        color | (entry.is_a?(Hunks::Line) ? 0 : Curses::A_BOLD)
      end

      def update_visibles
        @visibles = @files.each_with_object([]) do |entry, vs|
          vs << entry
          next unless entry.expanded
          entry.highlightable_subs.each do |entryy|
            vs << entryy
            vs.concat(entryy.highlightable_subs) if entryy.expanded
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

      def collapse
        return if @highlighted.is_a?(Hunks::Line) || !@highlighted.expanded
        @highlighted.expanded = false
        update_visibles
        redraw
      end

      def expand
        return if @highlighted.is_a?(Hunks::Line) || @highlighted.expanded
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
