module GitCrecord
  module Hunks
    class HunkBase
      attr_reader :selectable
      attr_accessor :expanded

      def initialize(selectable = true)
        @selectable = selectable
      end

      def subs
        []
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
