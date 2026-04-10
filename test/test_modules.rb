require_relative "test_helper"
require "folk_rules/part"
require "folk_rules/musical_context"
require "folk_rules/note"
require "folk_rules/modules/base"
require "folk_rules/modules/arpeggiator"
require "folk_rules/modules/chord_expand"
require "folk_rules/modules/note_repeat"

class TestModules < Minitest::Test
  NE = FolkRules::Part::NoteEvent

  def ctx(key: :c, scale: :major)
    FolkRules::MusicalContext.new(key: key, scale: scale)
  end

  def chord_events
    [
      NE.new(note: 48, velocity: 85, duration: 1.0, channel: 0), # C3
      NE.new(note: 52, velocity: 85, duration: 1.0, channel: 0), # E3
      NE.new(note: 55, velocity: 85, duration: 1.0, channel: 0)  # G3
    ]
  end

  # Arpeggiator

  def test_arpeggiator_up_picks_sequential_notes
    arp = FolkRules::Modules::Arpeggiator.new(mode: :up)
    events = chord_events
    notes = 4.times.map { arp.process(events, ctx, beat: 1, bar: 1).first.note }
    assert_equal [48, 52, 55, 48], notes
  end

  def test_arpeggiator_down
    arp = FolkRules::Modules::Arpeggiator.new(mode: :down)
    events = chord_events
    # Down starts at position 0, goes to -1 (wraps to 2), then -2 (1), etc.
    notes = 3.times.map { arp.process(events, ctx, beat: 1, bar: 1).first.note }
    assert_equal [48, 55, 52], notes
  end

  def test_arpeggiator_returns_empty_for_empty_input
    arp = FolkRules::Modules::Arpeggiator.new
    assert_empty arp.process([], ctx, beat: 1, bar: 1)
  end

  # ChordExpand

  def test_chord_expand_triad
    expand = FolkRules::Modules::ChordExpand.new(voicing: :triad)
    root = [NE.new(note: 48, velocity: 85, duration: 1.0, channel: 0)] # C3
    result = expand.process(root, ctx(key: :c, scale: :major), beat: 1, bar: 1)
    notes = result.map(&:note)
    # C major triad: C3(48), E3(52), G3(55)
    assert_equal [48, 52, 55], notes
  end

  def test_chord_expand_seventh
    expand = FolkRules::Modules::ChordExpand.new(voicing: :seventh)
    root = [NE.new(note: 48, velocity: 85, duration: 1.0, channel: 0)]
    result = expand.process(root, ctx(key: :c, scale: :major), beat: 1, bar: 1)
    notes = result.map(&:note)
    assert_equal 4, notes.size
  end

  def test_chord_expand_octave_double
    expand = FolkRules::Modules::ChordExpand.new(voicing: :triad, octave_double: true)
    root = [NE.new(note: 48, velocity: 85, duration: 1.0, channel: 0)]
    result = expand.process(root, ctx(key: :c, scale: :major), beat: 1, bar: 1)
    notes = result.map(&:note)
    assert_includes notes, 60 # octave above root
  end

  # NoteRepeat

  def test_note_repeat_produces_n_notes
    rep = FolkRules::Modules::NoteRepeat.new(repeats: 4, decay: 0.8)
    input = [NE.new(note: 48, velocity: 100, duration: 1.0, channel: 0)]
    result = rep.process(input, ctx, beat: 1, bar: 1)
    assert_equal 4, result.size
  end

  def test_note_repeat_decays_velocity
    rep = FolkRules::Modules::NoteRepeat.new(repeats: 3, decay: 0.5)
    input = [NE.new(note: 48, velocity: 100, duration: 1.0, channel: 0)]
    result = rep.process(input, ctx, beat: 1, bar: 1)
    vels = result.map(&:velocity)
    assert_equal 100, vels[0]
    assert_equal 50, vels[1]
    assert_equal 25, vels[2]
  end

  def test_note_repeat_duration_divides
    rep = FolkRules::Modules::NoteRepeat.new(repeats: 4, decay: 1.0)
    input = [NE.new(note: 48, velocity: 100, duration: 1.0, channel: 0)]
    result = rep.process(input, ctx, beat: 1, bar: 1)
    assert_in_delta 0.25, result.first.duration, 0.001
  end

  # Module chain via Part

  def test_part_module_chain
    gen = ->(_ctx, _beat, _bar) { chord_events }
    arp = FolkRules::Modules::Arpeggiator.new(mode: :up)
    part = FolkRules::Part.new(
      name: :test, type: :chord, bus: :pitched,
      generator: gen, modules: [arp]
    )
    events = part.generate(ctx, beat: 1, bar: 1)
    assert_equal 1, events.size # arp collapses chord to 1 note
  end
end
