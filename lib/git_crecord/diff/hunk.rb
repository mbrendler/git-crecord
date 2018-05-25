# frozen_string_literal: true

require_relative 'difference'
require_relative 'line'
require_relative '../ui/color'

module GitCrecord
  module Diff
    class Hunk < Difference
      def initialize(head)
        @head = head
        @expanded = true
        super()
      end

      def to_s
        @head
      end

      def x_offset
        3
      end

      def <<(line)
        subs << Line.new(line)
        self
      end

      def generate_diff
        return nil unless selected
        [generate_header, *subs.map(&:generate_diff).compact].join("\n")
      end

      def generate_header
        old_start, old_count, new_start, new_count = parse_header
        selectable_subs.each do |sub|
          next if sub.selected
          new_count -= 1 if sub.add?
          new_count += 1 if sub.del?
        end
        "@@ -#{old_start},#{old_count} +#{new_start},#{new_count} @@"
      end

      def parse_header
        match = @head.match(/@@ -(\d+)(,(\d+))? \+(\d+)(,(\d+))? @@/)
        raise "mismatching hunk-header - '#{@head}'" if match.nil?
        [match[1], match[3] || 1, match[4], match[6] || 1].map(&:to_i)
      end
    end
  end
end
