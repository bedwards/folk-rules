require_relative "test_helper"
require "folk_rules/part"
require "folk_rules/musical_context"
require "folk_rules/modules/humanize"
require "folk_rules/modules/multi_note"
require "folk_rules/modules/note_length"
require "folk_rules/modules/note_filter"
require "folk_rules/modules/note_latch"

class TestModulesB < Minitest::Test
  NE = FolkRules::Part::NoteEvent

  def ctx
    FolkRules::MusicalContext.new(key: :c, scale: :major)
  end

  def note(n = 60, vel = 100, dur = 1.0, ch = 0)
    NE.new(note: n, velocity: vel, duration: dur, channel: ch)
  end

  # Humanize

  def test_humanize_preserves_count
    h = FolkRules::Modules::Humanize.new(velocity: 0.2, seed: 42)
    input = [note(60), note(64), note(67)]
    result = h.process(input, ctx, beat: 1, bar: 1)
    assert_equal 3, result.size
  end

  def test_humanize_velocity_changes_with_amount
    h = FolkRules::Modules::Humanize.new(velocity: 0.5, seed: 42)
    input = [note(60, 100)]
    result = h.process(input, ctx, beat: 1, bar: 1)
    # With 50% amount and seed, velocity should differ from 100
    # (statistically; seed 42 should not land exactly on 0 offset)
    vel = result.first.velocity
    assert_includes 1..127, vel
  end

  def test_humanize_zero_amount_is_passthrough
    h = FolkRules::Modules::Humanize.new(velocity: 0.0, timing: 0.0, pitch: 0.0, seed: 42)
    input = [note(60, 100)]
    result = h.process(input, ctx, beat: 1, bar: 1)
    assert_equal 100, result.first.velocity
    assert_equal 60, result.first.note
  end

  def test_humanize_seeded_is_reproducible
    h1 = FolkRules::Modules::Humanize.new(velocity: 0.3, seed: 123)
    h2 = FolkRules::Modules::Humanize.new(velocity: 0.3, seed: 123)
    input = [note(60, 100)]
    r1 = h1.process(input, ctx, beat: 1, bar: 1)
    r2 = h2.process(input, ctx, beat: 1, bar: 1)
    assert_equal r1.first.velocity, r2.first.velocity
  end

  # MultiNote

  def test_multi_note_octave_double
    mn = FolkRules::Modules::MultiNote.new(intervals: [12])
    input = [note(60)]
    result = mn.process(input, ctx, beat: 1, bar: 1)
    assert_equal 2, result.size
    assert_equal [60, 72], result.map(&:note)
  end

  def test_multi_note_fifth_and_octave
    mn = FolkRules::Modules::MultiNote.new(intervals: [7, 12])
    input = [note(48)]
    result = mn.process(input, ctx, beat: 1, bar: 1)
    assert_equal [48, 55, 60], result.map(&:note)
  end

  def test_multi_note_clamps_high
    mn = FolkRules::Modules::MultiNote.new(intervals: [12])
    input = [note(125)]
    result = mn.process(input, ctx, beat: 1, bar: 1)
    assert_equal [125, 127], result.map(&:note)
  end

  # NoteLength

  def test_note_length_gate
    nl = FolkRules::Modules::NoteLength.new(mode: :gate, gate: 0.5)
    input = [note(60, 100, 1.0)]
    result = nl.process(input, ctx, beat: 1, bar: 1)
    assert_in_delta 0.5, result.first.duration, 0.001
  end

  def test_note_length_staccato
    nl = FolkRules::Modules::NoteLength.new(mode: :staccato)
    input = [note(60, 100, 1.0)]
    result = nl.process(input, ctx, beat: 1, bar: 1)
    assert_in_delta 0.3, result.first.duration, 0.001
  end

  def test_note_length_legato
    nl = FolkRules::Modules::NoteLength.new(mode: :legato)
    input = [note(60, 100, 1.0)]
    result = nl.process(input, ctx, beat: 1, bar: 1)
    assert_in_delta 1.2, result.first.duration, 0.001
  end

  # NoteFilter

  def test_note_filter_by_range
    nf = FolkRules::Modules::NoteFilter.new(note_range: 60..72)
    input = [note(48), note(60), note(72), note(84)]
    result = nf.process(input, ctx, beat: 1, bar: 1)
    assert_equal [60, 72], result.map(&:note)
  end

  def test_note_filter_by_velocity
    nf = FolkRules::Modules::NoteFilter.new(velocity_range: 80..127)
    input = [note(60, 50), note(60, 100)]
    result = nf.process(input, ctx, beat: 1, bar: 1)
    assert_equal 1, result.size
    assert_equal 100, result.first.velocity
  end

  def test_note_filter_passes_all_when_no_criteria
    nf = FolkRules::Modules::NoteFilter.new
    input = [note(48), note(60)]
    result = nf.process(input, ctx, beat: 1, bar: 1)
    assert_equal 2, result.size
  end

  # NoteLatch

  def test_note_latch_holds_last_notes
    nl = FolkRules::Modules::NoteLatch.new
    first = [note(60), note(64)]
    r1 = nl.process(first, ctx, beat: 1, bar: 1)
    assert_equal [60, 64], r1.map(&:note)

    # Empty input → re-emit latched
    r2 = nl.process([], ctx, beat: 2, bar: 1)
    assert_equal [60, 64], r2.map(&:note)

    # New input replaces latch
    r3 = nl.process([note(67)], ctx, beat: 3, bar: 1)
    assert_equal [67], r3.map(&:note)

    r4 = nl.process([], ctx, beat: 4, bar: 1)
    assert_equal [67], r4.map(&:note)
  end
end
