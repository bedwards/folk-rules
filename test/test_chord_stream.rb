require_relative "test_helper"
require "folk_rules/input/chord_stream"
require "folk_rules/note"

class TestChordStream < Minitest::Test
  def cs
    FolkRules::Input::ChordStream.new
  end

  def note_on(note, vel = 100)
    [0x90, note, vel]
  end

  def note_off(note)
    [0x80, note, 0]
  end

  def test_identifies_c_major_triad
    s = cs
    s.feed([note_on(48), note_on(52), note_on(55)]) # C3, E3, G3
    assert_equal :c, s.current_chord[:root]
    assert_equal :major, s.current_chord[:quality]
  end

  def test_identifies_a_minor_triad
    s = cs
    s.feed([note_on(57), note_on(60), note_on(64)]) # A3, C4, E4
    assert_equal :a, s.current_chord[:root]
    assert_equal :minor, s.current_chord[:quality]
  end

  def test_identifies_g7
    s = cs
    s.feed([note_on(55), note_on(59), note_on(62), note_on(65)]) # G3, B3, D4, F4
    assert_equal :g, s.current_chord[:root]
    assert_equal :seventh, s.current_chord[:quality]
  end

  def test_identifies_power_chord
    s = cs
    s.feed([note_on(40), note_on(47)]) # E2, B2
    assert_equal :e, s.current_chord[:root]
    assert_equal :power, s.current_chord[:quality]
  end

  def test_chord_change_callback_fires
    s = cs
    changes = []
    s.on_chord_change { |chord| changes << chord }
    # Each note-on can trigger a change as intervals form
    s.feed([note_on(48), note_on(52), note_on(55)])
    s.feed([note_off(48), note_off(52), note_off(55)])
    s.feed([note_on(57), note_on(60), note_on(64)])
    # Multiple intermediate chords are detected (C+E, C+E+G, A+C, A+C+E)
    assert changes.size >= 2, "expected at least 2 chord changes, got #{changes.size}"
    # First detected chord with C root
    c_chords = changes.select { |c| c[:root] == :c }
    refute_empty c_chords
  end

  def test_note_off_updates_held
    s = cs
    s.feed([note_on(48), note_on(52), note_on(55)])
    assert_equal 3, s.held_notes.size
    s.feed([note_off(55)])
    assert_equal 2, s.held_notes.size
  end

  def test_history_tracks_changes
    s = cs
    s.feed([note_on(48), note_on(52), note_on(55)])
    s.feed([note_off(48), note_off(52), note_off(55)])
    s.feed([note_on(57), note_on(60), note_on(64)])
    assert s.history.size >= 1
  end

  def test_velocity_zero_note_on_is_note_off
    s = cs
    s.feed([note_on(48), note_on(52)])
    s.feed([[0x90, 48, 0]]) # note-on with velocity 0 = note off
    assert_equal [52], s.held_notes
  end

  def test_unknown_chord_still_detected
    s = cs
    # Some unusual interval set
    s.feed([note_on(48), note_on(49), note_on(53)])
    refute_nil s.current_chord
    assert_equal :c, s.current_chord[:root]
    assert_equal :unknown, s.current_chord[:quality]
  end

  def test_single_note_gives_nil
    s = cs
    s.feed([note_on(60)])
    assert_nil s.current_chord
  end
end
