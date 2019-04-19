# frozen_string_literal: true

require 'curses'

module GitCrecord
  module UI
    module Color
      MAP = {
        normal: 1,
        green: 2,
        red: 3,
        hl: 4,
        status_bar: 5
      }.freeze

      def self.init
        Curses.start_color
        Curses.use_default_colors
        Curses.init_pair(MAP[:normal], -1, -1)
        Curses.init_pair(MAP[:green], Curses::COLOR_GREEN, -1)
        Curses.init_pair(MAP[:red], Curses::COLOR_RED, -1)
        Curses.init_pair(MAP[:hl], Curses::COLOR_BLACK, Curses::COLOR_GREEN)
        Curses.init_pair(
          MAP[:status_bar], Curses::COLOR_BLACK, Curses::COLOR_BLUE
        )
      end

      MAP.each_pair do |name, number|
        define_singleton_method(name) { Curses.color_pair(number) }
      end
    end
  end
end
