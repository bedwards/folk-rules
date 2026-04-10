require_relative "test_helper"

class TestVersion < Minitest::Test
  def test_version_is_a_nonempty_string
    refute_nil FolkRules::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, FolkRules::VERSION)
  end
end
