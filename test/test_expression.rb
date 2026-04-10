require_relative "test_helper"
require "folk_rules/part"
require "folk_rules/musical_context"
require "folk_rules/modules/fill"
require "folk_rules/modules/pitch_bend"
require "folk_rules/cc_lfo"

class TestExpression < Minitest::Test
  NE = FolkRules::Part::NoteEvent

  def ctx
    FolkRules::MusicalContext.new(key: :c, scale: :major, beats_per_bar: 4)
  end

  def note(n = 60, vel = 100, dur = 1.0, ch = 0)
    NE.new(note: n, velocity: vel, duration: dur, channel: ch)
  end

  # Fill

  def test_fill_triggers_on_configured_bar
    fill = FolkRules::Modules::Fill.new(every: 4, density: :medium, seed: 42)
    input = [note(60)]
    # Not a fill bar
    r1 = fill.process(input, ctx, beat: 1, bar: 3)
    assert_equal 1, r1.size
    # Fill bar (bar 4, divisible by 4)
    r2 = fill.process(input, ctx, beat: 1, bar: 4)
    assert r2.size > 1, "fill should add extra events on fill bar"
  end

  def test_fill_density_heavy_produces_more
    fill_light = FolkRules::Modules::Fill.new(every: 1, density: :light, seed: 42)
    fill_heavy = FolkRules::Modules::Fill.new(every: 1, density: :heavy, seed: 42)
    input = [note(60)]
    light = fill_light.process(input, ctx, beat: 1, bar: 1)
    heavy = fill_heavy.process(input, ctx, beat: 1, bar: 1)
    assert heavy.size > light.size
  end

  # PitchBend

  def test_pitch_bend_with_full_probability
    pb = FolkRules::Modules::PitchBend.new(amount: 2, direction: :up, probability: 1.0, seed: 42)
    input = [note(60)]
    result = pb.process(input, ctx, beat: 1, bar: 1)
    assert_equal 1, result.size
    assert_equal 62, result.first.note # shifted up by 2
  end

  def test_pitch_bend_with_zero_probability
    pb = FolkRules::Modules::PitchBend.new(amount: 2, probability: 0.0, seed: 42)
    input = [note(60)]
    result = pb.process(input, ctx, beat: 1, bar: 1)
    assert_equal 60, result.first.note # unchanged
  end

  # CcLfo

  def test_cc_lfo_sine_range
    lfo = FolkRules::CcLfo.new(name: :test, bus: :pitched, cc: 74, wave: :sine, min: 0, max: 127)
    values = (1..4).map { |b| lfo.value_at(beat: b, beats_per_bar: 4) }
    assert(values.all? { |v| (0..127).cover?(v) })
  end

  def test_cc_lfo_square
    lfo = FolkRules::CcLfo.new(name: :test, bus: :pitched, cc: 74, wave: :square, min: 0, max: 127)
    v1 = lfo.value_at(beat: 1, beats_per_bar: 4)
    v3 = lfo.value_at(beat: 3, beats_per_bar: 4)
    assert_equal 127, v1 # first half = high
    assert_equal 0, v3   # second half = low
  end

  def test_cc_lfo_triangle_symmetry
    lfo = FolkRules::CcLfo.new(name: :test, bus: :pitched, cc: 1, wave: :triangle, min: 0, max: 100)
    v1 = lfo.value_at(beat: 1, beats_per_bar: 4)
    v3 = lfo.value_at(beat: 3, beats_per_bar: 4)
    # Triangle: beat 1 (phase 0) = 0, beat 3 (phase 0.5) = 100
    assert_equal 0, v1
    assert_equal 100, v3
  end
end
