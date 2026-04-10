require_relative "test_helper"
require "folk_rules/tui"
require "folk_rules/scheduler"

class TestTui < Minitest::Test
  def test_render_frame_contains_header
    tui = FolkRules::Tui.new
    frame = tui.render_frame
    assert_includes frame, "folk-rules TUI"
    assert_includes frame, FolkRules::VERSION
  end

  def test_render_frame_shows_stopped_by_default
    tui = FolkRules::Tui.new
    frame = tui.render_frame
    assert_includes frame, "STOPPED"
  end

  def test_update_changes_displayed_state
    tui = FolkRules::Tui.new
    tui.update(bpm: 120.0, bar: 3, beat: 2, running: true)
    frame = tui.render_frame
    assert_includes frame, "PLAYING"
    assert_includes frame, "120.0"
    assert_includes frame, "Bar: \e[1m3"
    assert_includes frame, "Beat: \e[1m2"
  end

  def test_update_chord
    tui = FolkRules::Tui.new
    tui.update(chord: {root: :g, quality: :major})
    frame = tui.render_frame
    assert_includes frame, "gmajor"
  end

  def test_event_log
    tui = FolkRules::Tui.new
    evt = FolkRules::Scheduler::MidiEvent.new(
      tick: 1, beat: 1, bar: 1, channel: 0, note: 60, velocity: 100,
      duration_steps: 1, bus: :pitched
    )
    tui.update(event: evt)
    frame = tui.render_frame
    assert_includes frame, "NOTE ch=0 n=60 v=100"
  end

  def test_cc_event_log
    tui = FolkRules::Tui.new
    cc = FolkRules::Scheduler::CcEvent.new(
      tick: 1, beat: 1, bar: 1, channel: 0, cc: 74, value: 64, bus: :pitched
    )
    tui.update(cc_event: cc)
    frame = tui.render_frame
    assert_includes frame, "CC ch=0 cc=74 val=64"
  end

  def test_quit_footer
    tui = FolkRules::Tui.new
    frame = tui.render_frame
    assert_includes frame, "Press q to quit"
  end
end
