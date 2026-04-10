require_relative "test_helper"
require "folk_rules/song"
require "folk_rules/generators/bass"
require "folk_rules/generators/chord"
require "folk_rules/generators/melody"
require "folk_rules/generators/arp"

class TestGenerators < Minitest::Test
  def ctx(key: :c, scale: :major, chord: :c, beats_per_bar: 4)
    FolkRules::MusicalContext.new(
      key: key, scale: scale,
      progression: [chord], beats_per_bar: beats_per_bar
    )
  end

  # Bass

  def test_bass_plays_root
    gen = FolkRules::Generators::Bass.new(octave: 2, pattern: "x...")
    events = gen.call(ctx(chord: :c), 1, 1)
    assert_equal 1, events.size
    assert_equal 36, events.first.note # C2 = 36
  end

  def test_bass_plays_bb_root
    gen = FolkRules::Generators::Bass.new(octave: 2, pattern: "x...")
    events = gen.call(ctx(chord: :bb), 1, 1)
    assert_equal 1, events.size
    assert_equal 46, events.first.note # Bb2 = 46
  end

  # Chord

  def test_chord_plays_triad
    gen = FolkRules::Generators::Chord.new(octave: 3, voicing: :major, pattern: "x...")
    events = gen.call(ctx(chord: :c), 1, 1)
    assert_equal 3, events.size
    notes = events.map(&:note)
    assert_equal [48, 52, 55], notes # C3, E3, G3
  end

  def test_chord_minor
    gen = FolkRules::Generators::Chord.new(octave: 3, voicing: :minor, pattern: "x...")
    events = gen.call(ctx(chord: :a), 1, 1)
    notes = events.map(&:note)
    assert_equal [57, 60, 64], notes # A3, C4, E4
  end

  # Melody

  def test_melody_walks_scale
    # Pattern "xxxx" hits on every beat (4 beats = 4 chars)
    gen = FolkRules::Generators::Melody.new(octave: 4, pattern: "xxxx", step_size: 1, direction: :up)
    c = ctx(key: :c, scale: :major)
    notes = 4.times.map { |i| gen.call(c, i + 1, 1).first&.note }.compact
    assert_equal [60, 62, 64, 65], notes # C4, D4, E4, F4
  end

  def test_melody_g_minor_pent_override
    gen = FolkRules::Generators::Melody.new(octave: 4, pattern: "xxxx", step_size: 1, direction: :up)
    c = ctx(key: :g, scale: :minor_pentatonic)
    notes = 4.times.map { |i| gen.call(c, i + 1, 1).first&.note }.compact
    notes.each do |n|
      assert FolkRules::Note.in_scale?(n, :g4, :minor_pentatonic),
        "note #{n} not in G minor pentatonic"
    end
  end

  # Arp

  def test_arp_up_mode
    gen = FolkRules::Generators::Arp.new(octave: 3, mode: :up, voicing: :major,
      octave_range: 1, pattern: "xxxx")
    c = ctx(chord: :c)
    notes = 4.times.map { |i| gen.call(c, i + 1, 1).first&.note }.compact
    assert_equal [48, 52, 55, 48], notes # C3, E3, G3, wrap to C3
  end

  def test_arp_returns_empty_without_chord
    gen = FolkRules::Generators::Arp.new(pattern: "x...")
    c = FolkRules::MusicalContext.new # no progression
    events = gen.call(c, 1, 1)
    assert_empty events
  end
end
