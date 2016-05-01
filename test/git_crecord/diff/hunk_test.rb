require_relative '../../test_helper'

class HunkTest < Minitest::Test
  include GitCrecord::Diff

  def test_strings
    hunk = Hunk.new('1234567890' * 5)
    expected = %w(12345678901 23456789012 34567890123 45678901234 567890)
    assert_equal(expected, hunk.strings(19))
  end

  def test_max_height
    assert_equal(1, Hunk.new('').max_height(10))
    assert_equal(1, Hunk.new('1234567890').max_height(18))
    assert_equal(2, Hunk.new('12345678901').max_height(18))
  end

  def test_parse_header
    assert_equal([1, 2, 3, 4], Hunk.new('@@ -1,2 +3,4 @@').parse_header)
    assert_equal([1, 1, 3, 4], Hunk.new('@@ -1 +3,4 @@').parse_header)
    assert_equal([1, 2, 3, 1], Hunk.new('@@ -1,2 +3 @@').parse_header)
  end

  def test_parse_header_failure
    hunk = Hunk.new('ugly header')
    assert_raises(RuntimeError){ hunk.parse_header }
  end
end
