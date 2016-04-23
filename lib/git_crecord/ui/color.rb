require 'curses'

module GitCrecord
  module UI
    module Color
      module_function

      MAP = {
        normal: 1,
        green: 2,
        red: 3,
        hl: 4
      }.freeze

      def init
        Curses.start_color
        Curses.use_default_colors
        Curses.init_pair(MAP[:normal], -1, -1)
        Curses.init_pair(MAP[:green], Curses::COLOR_GREEN, -1)
        Curses.init_pair(MAP[:red], Curses::COLOR_RED, -1)
        Curses.init_pair(MAP[:hl], Curses::COLOR_WHITE, Curses::COLOR_GREEN)
      end

      MAP.each_pair do |name, number|
        define_method(name){ Curses.color_pair(number) }
      end
    end
  end
end
