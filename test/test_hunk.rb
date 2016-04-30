require 'minitest/autorun'
require_relative '../lib/git_crecord/diff/hunk'

class HunkTest < Minitest::Test
  include GitCrecord::Diff

  def test_parse_header
    assert_equal([1, 2, 3, 4], Hunk.new('@@ -1,2 +3,4 @@').parse_header)
    assert_equal([1, 1, 3, 4], Hunk.new('@@ -1 +3,4 @@').parse_header)
    assert_equal([1, 2, 3, 1], Hunk.new('@@ -1,2 +3 @@').parse_header)
  end
end
