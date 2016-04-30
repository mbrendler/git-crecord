require_relative '../../test_helper'

class HunkTest < Minitest::Test
  include GitCrecord::Diff

  def test_strings
    hunk = Hunk.new('1234567890' * 5)
    expected = %w(12345678901 23456789012 34567890123 45678901234 567890)
    assert_equal(expected, hunk.strings(11))
  end

  def test_parse_header
    assert_equal([1, 2, 3, 4], Hunk.new('@@ -1,2 +3,4 @@').parse_header)
    assert_equal([1, 1, 3, 4], Hunk.new('@@ -1 +3,4 @@').parse_header)
    assert_equal([1, 2, 3, 1], Hunk.new('@@ -1,2 +3 @@').parse_header)
  end
end
