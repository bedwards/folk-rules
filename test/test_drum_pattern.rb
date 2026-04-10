require_relative "test_helper"
require "folk_rules/drum_pattern"

class TestDrumPattern < Minitest::Test
  def test_basic_kick_pattern
    dp = FolkRules::DrumPattern.new(name: :kick, pattern: "x...x...x...x...")
    assert_equal 16, dp.length
    assert_equal 36, dp.note
    hits = dp.hits
    assert_equal [0, 4, 8, 12], hits.map { |h| h[:step] }
    assert_equal [100, 100, 100, 100], hits.map { |h| h[:velocity] }
  end

  def test_accent_and_ghost
    dp = FolkRules::DrumPattern.new(name: :snare, pattern: "..X...o.")
    hits = dp.hits
    assert_equal [{step: 2, velocity: 127}, {step: 6, velocity: 50}], hits
  end

  def test_dash_is_rest
    dp = FolkRules::DrumPattern.new(name: :kick, pattern: "x---")
    assert_equal 1, dp.hits.size
  end

  def test_unknown_drum_raises
    assert_raises(ArgumentError) do
      FolkRules::DrumPattern.new(name: :kazoo, pattern: "x...")
    end
  end

  def test_unknown_char_raises
    assert_raises(ArgumentError) do
      FolkRules::DrumPattern.new(name: :kick, pattern: "x!..")
    end
  end
end
