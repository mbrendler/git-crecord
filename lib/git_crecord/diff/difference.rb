module GitCrecord
  module Diff
    class Difference
      attr_accessor :expanded
      attr_accessor :y1, :y2
      attr_reader :subs

      def initialize
        @subs = []
      end

      def selectable?
        true
      end

      def selectable_subs
        @selectable_subs ||= subs.select(&:selectable?)
      end

      def selected
        s = selectable_subs.map(&:selected).uniq
        return s[0] if s.size == 1
        :partly
      end

      def selected=(value)
        selectable_subs.each{ |sub| sub.selected = value }
      end
    end
  end
end
