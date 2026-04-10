require_relative "test_helper"
require "folk_rules/song"

class TestSongDSL < Minitest::Test
  def test_basic_song_creation
    song = FolkRules.song "test" do
      bus :drums, to: "folk_drums"
      drums :beat, bus: :drums do
        kick "x...x...x...x..."
      end
    end

    assert_equal "test", song.name
    assert_equal 1, song.drum_parts.size
    assert_equal :beat, song.drum_parts.first.name
    assert_equal 1, song.drum_parts.first.patterns.size
  end

  def test_context_set
    song = FolkRules.song "ctx" do
      context_set key: :bb, scale: :major, beats_per_bar: 3
    end

    assert_equal :bb, song.context.key
    assert_equal :major, song.context.scale
    assert_equal 3, song.context.beats_per_bar
  end

  def test_multiple_drum_voices
    song = FolkRules.song "kit" do
      bus :drums, to: "folk_drums"
      drums :full, bus: :drums do
        kick "x...x..."
        snare "....x..."
        hat_closed "x.x.x.x."
      end
    end

    assert_equal 3, song.drum_parts.first.patterns.size
    names = song.drum_parts.first.patterns.map(&:name)
    assert_equal [:kick, :snare, :hat_closed], names
  end
end
