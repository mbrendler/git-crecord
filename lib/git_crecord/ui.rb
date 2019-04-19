# frozen_string_literal: true

require 'curses'
require_relative 'ui/color'
require_relative 'ui/hunks_window'
require_relative 'ui/status_bar'

module GitCrecord
  module UI
    ACTIONS = {
      'q' => :quit,
      's' => :stage,
      'c' => :commit,
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
      ''.ord => :highlight_next_hunk,
      ''.ord => :highlight_previous_hunk,
      ' ' => :toggle_selection,
      'A' => :toggle_all_selections,
      '?' => :help_window,
      'R' => :redraw,
      Curses::KEY_RESIZE => :resize
    }.freeze

    def self.run(files)
      Curses.init_screen.keypad = true
      Color.init
      Curses.clear
      Curses.noecho
      Curses.curs_set(0)
      pad = Curses::Pad.new(1, 1).tap { |p| p.keypad = true }
      run_loop(HunksWindow.new(pad, files))
    ensure
      Curses.close_screen
    end

    def self.run_loop(win)
      loop do
        StatusBar.refresh(win)
        c = win.getch
        next if ACTIONS[c].nil?

        quit = win.send(ACTIONS[c])
        break quit if quit == :quit
      end
    end
  end
end
