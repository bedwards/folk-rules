require_relative "test_helper"
require "folk_rules/verifier"

class TestVerifier < Minitest::Test
  def test_verify_01_kick
    song = FolkRules.song "01_kick" do
      bus :drums, to: "folk_drums"
      drums :beat, bus: :drums do
        kick "x...x...x...x..."
      end
    end

    result = FolkRules::Verifier.new(song: song, bars: 4).run
    assert result.passed, "verifier should pass: #{result.checks.reject(&:ok).map(&:name)}"
    assert result.events.size > 0
  end

  def test_verify_02_four_on_floor
    song = FolkRules.song "02_four_on_floor" do
      context_set beats_per_bar: 4
      bus :drums, to: "folk_drums"
      drums :kit, bus: :drums, channel: 9 do
        kick "x...x...x...x..."
        snare "....x.......x..."
        hat_closed "x.x.x.x.x.x.x.x."
      end
    end

    result = FolkRules::Verifier.new(song: song, bars: 2).run
    assert result.passed
    # Kick: 4/bar × 2 = 8, Snare: 2/bar × 2 = 4, Hats: pattern dependent
    kick_count = result.events.count { |e| e.note == 36 }
    assert_equal 8, kick_count
  end
end
