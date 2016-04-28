require 'curses'
require_relative 'color'
require_relative 'help_window'
require_relative '../git'

module GitCrecord
  module UI
    class QuitAction
      def initialize(&block)
        @block = block
      end

      def call
        @block.call
      end

      def ==(other)
        :quit == other
      end
    end

    class HunksWindow
      SELECTED_MAP = {true => 'X', false => ' ', :partly => '~'}.freeze

      def initialize(win, files)
        @win = win
        @files = files
        @visibles = @files
        @highlighted = @files[0]
        @highlighted_y1 = 0
        @highlighted_y2 = 0
        @scroll_position = 0

        resize
      end

      def getch
        @win.getch
      end

      def refresh
        @win.clear
        print_list(@files)
        @win.refresh(scroll_position(@height), 0, 0, 0, Curses.lines - 1, @width)
      end

      def resize
        new_height = [Curses.lines, height(Curses.cols)].max
        return if @width == Curses.cols && @height == new_height
        @width = Curses.cols
        @height = new_height
        @win.resize(@height, @width)
        refresh
      end

      def height(width, hunks = @files)
        hunks.reduce(0) do |h, entry|
          h + entry.strings(width - 5).size + height(width - 3, entry.subs)
        end
      end

      def scroll_position(h)
        if @scroll_position + 3 > @highlighted_y1
          @scroll_position = @highlighted_y1 - 3
        elsif @scroll_position - 4 + Curses.lines <= @highlighted_y2
          @scroll_position = [@highlighted_y2 + 4, h].min - Curses.lines
        end
        @scroll_position
      end

      def print_list(list, width: Curses.cols, x_offset: 0, line_number: -1)
        list.each do |entry|
          line_number = print_entry(entry, width, x_offset, line_number)
          next unless entry.expanded
          line_number = print_list(
            entry.subs,
            width: width, x_offset: x_offset + 3, line_number: line_number
          )
        end
        line_number
      end

      def print_entry(entry, width, x_offset, line_number)
        is_highlighted = entry == @highlighted
        @highlighted_y1 = line_number + 1 if is_highlighted
        entry.strings(width - x_offset - 5).each_with_index do |string, index|
          @win.attrset(entry.is_a?(Hunks::File) && is_highlighted ? attrs(entry) : 0)
          @win.setpos(line_number += 1, x_offset)
          if index == 0 && entry.selectable
            @win.addstr("[#{SELECTED_MAP.fetch(entry.selected)}]  ")
          else
            @win.addstr('     ')
          end
          @win.attrset(attrs(entry))
          @win.addstr(string)
          add_spaces = (width - x_offset - 5 - string.size)
          @win.addstr(' ' * add_spaces) if is_highlighted && add_spaces > 0
        end
        @highlighted_y2 = line_number if is_highlighted
        line_number
      end

      def attrs(entry)
        color = Color.normal
        if entry.is_a?(Hunks::HunkLine)
          color = Color.green if entry.add?
          color = Color.red if entry.del?
        end
        color = Color.hl if entry == @highlighted
        color | (entry.is_a?(Hunks::HunkLine) ? 0 : Curses::A_BOLD)
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
        to_highlight = @visibles[@visibles.index(@highlighted) + 1]
        return if to_highlight.nil?
        @highlighted = to_highlight
        refresh
      end

      def highlight_previous
        to_highlight = @visibles[@visibles.index(@highlighted) - 1]
        return if to_highlight.nil?
        @highlighted = to_highlight
        refresh
      end

      def collapse
        return if @highlighted.is_a?(Hunks::HunkLine)
        @highlighted.expanded = false
        update_visibles
        refresh
      end

      def expand
        return if @highlighted.is_a?(Hunks::HunkLine)
        @highlighted.expanded = true
        update_visibles
        @highlighted = @visibles[@visibles.index(@highlighted) + 1]
        refresh
      end

      def toggle_fold
        @highlighted.expanded = !@highlighted.expanded
        update_visibles
        refresh
      end

      def highlight_first
        return if @highlighted == @visibles[0]
        @highlighted = @visibles[0]
        refresh
      end

      def highlight_last
        return if @highlighted == @visibles[-1]
        @highlighted = @visibles[-1]
        refresh
      end

      def toggle_selection
        @highlighted.selected = !@highlighted.selected
        refresh
      end

      def toggle_all_selections
        new_selected = @files[0].selected == false
        @files.each{ |file| file.selected = new_selected }
        refresh
      end

      def help_window
        HelpWindow.show
        refresh
      end
    end
  end
end
