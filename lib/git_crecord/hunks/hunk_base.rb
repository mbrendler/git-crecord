module GitCrecord
  module Hunks
    class HunkBase
      attr_accessor :expanded
      attr_accessor :y1, :y2

      def selectable?
        true
      end

      def highlightable_subs
        subs
      end

      def selected
        s = highlightable_subs.map(&:selected).uniq
        return s[0] if s.size == 1
        :partly
      end

      def selected=(value)
        highlightable_subs.each{ |sub| sub.selected = value }
      end
    end
  end
end
