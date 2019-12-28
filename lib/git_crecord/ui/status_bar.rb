# frozen_string_literal: true

require 'curses'
require_relative 'color'
require_relative '../git'

module GitCrecord
  module UI
    module StatusBar
      def self.refresh(main_win)
        write_left(main_win)
        fill_to_eol
        write_right(main_win)
        win.refresh
      end

      def self.write_left(_main_win)
        win.setpos(0, 0)
        win.addstr(" #{branch}")
      end

      def self.write_right(main_win)
        str = " #{reverse ? '[reverse]' : ''} #{main_win.highlight_position} "
        win.setpos(0, [0, win.maxx - str.size].max)
        win.addstr(str)
      end

      def self.fill_to_eol
        fill_width = win.maxx - win.curx
        win.addstr(' ' * fill_width) if fill_width.positive?
      end

      def self.win
        @win ||= Curses::Window.new(1, Curses.cols, 0, 0).tap do |win|
          win.attrset(Color.status_bar | Curses::A_BOLD)
        end
      end

      def self.branch
        @branch = Git.branch
      end

      def self.reverse
        @reverse
      end

      def self.reverse=(reverse)
        @reverse = reverse
      end
    end
  end
end
