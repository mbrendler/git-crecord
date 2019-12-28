# frozen_string_literal: true

require_relative 'difference'
require_relative 'hunk'
require_relative '../ui/color'

module GitCrecord
  module Diff
    class File < Difference
      attr_reader :filename_a
      attr_reader :type

      def initialize(filename_a, filename_b, type: :modified, reverse: false)
        @filename_a = filename_a
        @filename_b = filename_b
        @type = type
        @expanded = false
        super(reverse: reverse)
      end

      def to_s
        prefix = { modified: 'M', new: 'A', untracked: '?' }.fetch(type)
        return "#{prefix} #{@filename_a}" if @filename_a == @filename_b

        "#{prefix} #{filename_a} -> #{filename_b}"
      end

      def info_string
        line_count = subs.reduce(0) { |a, e| e.selectable_subs.size + a }
        "  #{subs.size} hunk(s), #{line_count} line(s) changed"
      end

      def strings(width)
        result = super
        return result unless expanded

        result += info_string.scan(/.{1,#{content_width(width)}}/)
        result << ''
      end

      def max_height(width)
        super + ((info_string.size - 1).abs / content_width(width)) + 2
      end

      def x_offset
        0
      end

      def <<(hunk)
        subs << Hunk.new(hunk, reverse: @reverse)
        self
      end

      def add_hunk_line(line)
        subs.last << line
      end

      def generate_diff
        return unless selected

        [
          "diff --git a/#{@filename_a} b/#{@filename_b}",
          "--- a/#{@filename_a}",
          "+++ b/#{@filename_b}",
          *subs.map(&:generate_diff).compact,
          ''
        ].join("\n")
      end

      alias prefix_style style

      def make_empty(type = 'empty')
        subs << PseudoLine.new(type)
      end
    end
  end
end
