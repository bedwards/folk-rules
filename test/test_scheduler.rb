require_relative "test_helper"
require "folk_rules/song"
require "folk_rules/scheduler"
require "folk_rules/memory_output"
require "folk_rules/clock"

class TestScheduler < Minitest::Test
  def make_song
    FolkRules.song "test_sched" do
      context_set beats_per_bar: 4, subdivision: 16
      bus :drums, to: "folk_drums"
      drums :beat, bus: :drums, channel: 9 do
        kick "x...x...x...x..."
        snare "....x.......x..."
      end
    end
  end

  def test_simulate_produces_events
    song = make_song
    output = FolkRules::MemoryOutput.new
    scheduler = FolkRules::Scheduler.new(song: song, outputs: {drums: output})
    events = scheduler.simulate(bars: 2)

    refute_empty events
    kick_events = events.select { |e| e.note == 36 }
    snare_events = events.select { |e| e.note == 38 }
    # 2 bars × 4 kicks per bar = 8 kicks
    assert_equal 8, kick_events.size
    # 2 bars × 2 snares per bar = 4 snares
    assert_equal 4, snare_events.size
  end

  def test_events_have_correct_channel
    song = make_song
    scheduler = FolkRules::Scheduler.new(song: song, outputs: {drums: FolkRules::MemoryOutput.new})
    events = scheduler.simulate(bars: 1)
    assert(events.all? { |e| e.channel == 9 })
  end

  def test_memory_output_captures_note_ons
    song = make_song
    output = FolkRules::MemoryOutput.new
    FolkRules::Scheduler.new(song: song, outputs: {drums: output}).simulate(bars: 1)
    note_ons = output.note_ons
    refute_empty note_ons
    assert(note_ons.all? { |n| n[:channel] == 9 })
  end
end
