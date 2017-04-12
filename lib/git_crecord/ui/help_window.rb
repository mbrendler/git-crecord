require 'curses'

module GitCrecord
  module UI
    module HelpWindow
      CONTENT = <<EOS.freeze
  q      - quit
  s      - stage selection and quit
  c      - commit selection and quit
  j / ↓  - down
  k / ↑  - up
  h / ←  - collapse hunk
  l / →  - expand hunk
  f      - toggle fold
  g      - go to first line
  G      - go to last line
  C-P    - up to previous hunk / file
  C-N    - down to next hunk / file
  SPACE  - toggle selection
  A      - toggle all selections
  ?      - display help
  R      - force redraw
EOS

      def self.show
        win = Curses::Window.new(height, width, 0, 0)
        win.box('|', '-')
        CONTENT.split("\n").each_with_index do |line, index|
          win.setpos(index + 1, 1)
          win.addstr(line)
        end
        win.getch
        win.close
      end

      def self.width
        CONTENT.lines.map(&:size).max + 3
      end

      def self.height
        CONTENT.lines.size + 2
      end
    end
  end
end
