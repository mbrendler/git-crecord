# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/git_crecord/diff/hunk'

RSpec.describe GitCrecord::Diff::Hunk do
  describe '#strings' do
    it 'splits the strings by the given length' do
      hunk = described_class.new('1234567890' * 5)
      expect(hunk.strings(19)).to eq(
        %w[12345678901 23456789012 34567890123 45678901234 567890]
      )
    end
  end

  describe '#max_height' do
    it 'returns 1 with empty string' do
      expect(described_class.new('').max_height(10)).to eq(1)
    end

    it 'returns 1 with a string that matches the given line length' do
      expect(described_class.new('1234567890').max_height(18)).to eq(1)
    end

    it 'returns 2 with a string that is one char longer than the length' do
      expect(described_class.new('12345678901').max_height(18)).to eq(2)
    end
  end

  describe '#parse_header' do
    it 'works with all four position values' do
      expect(described_class.new('@@ -1,2 +3,4 @@').parse_header).to eq(
        [1, 2, 3, 4]
      )
    end

    it 'works without old_count value' do
      expect(described_class.new('@@ -1 +3,4 @@').parse_header).to eq(
        [1, 1, 3, 4]
      )
    end

    it 'works without new_count value' do
      expect(described_class.new('@@ -1,2 +3 @@').parse_header).to eq(
        [1, 2, 3, 1]
      )
    end

    it 'fails with an invalid header' do
      hunk = described_class.new('ugly header')
      expect { hunk.parse_header }.to raise_error(RuntimeError)
    end
  end
end
