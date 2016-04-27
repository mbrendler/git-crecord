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
l / →  - expand
f      - toggle fold
g      - go to first line
G      - go to last line
SPACE  - toggle selection
A      - toggle all selections
?      - this help window
EOS

      def self.show
        win = Curses::Window.new(height, width, 0, 0)
        win.box('|', '-')
        CONTENT.split("\n").each_with_index do |line, index|
          win.setpos(index + 1, 3)
          win.addstr(line)
        end
        win.getch
      end

      def self.width
        CONTENT.lines.map(&:size).max + 5
      end

      def self.height
        CONTENT.lines.size + 2
      end
    end
  end
end
