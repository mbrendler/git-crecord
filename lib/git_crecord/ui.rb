require 'curses'
require_relative 'ui/color'
require_relative 'ui/hunks_window'

module GitCrecord
  module UI
    ACTIONS = {
      'q' => :quit,
      Curses::KEY_RESIZE => :nil?, # Do nothing but refresh screen
      'j' => :highlight_next,
      Curses::KEY_DOWN => :highlight_next,
      'k' => :highlight_previous,
      Curses::KEY_UP => :highlight_previous,
      'h' => :collapse,
      Curses::KEY_LEFT => :collapse,
      'l' => :expand,
      Curses::KEY_RIGHT => :expand,
      'f' => :toggle_fold,
      'g' => :highlight_first,
      'G' => :highlight_last,
      ' ' => :toggle_selection,
      'A' => :toggle_all_selections,
      's' => :stage,
      'c' => :commit
    }.freeze

    def self.run(files)
      Curses.init_screen.keypad = true
      Color.init
      Curses.clear
      Curses.noecho
      Curses.curs_set(0)
      win = HunksWindow.new(Curses::Pad.new(Curses.lines, Curses.cols), files)
      run_loop(win)
    ensure
      Curses.close_screen
    end

    def self.run_loop(win)
      Curses.refresh
      win.refresh
      loop do
        c = Curses.getch
        next if ACTIONS[c].nil?
        quit = win.send(ACTIONS[c])
        break if quit == :quit
        win.refresh
      end
    end
  end
end