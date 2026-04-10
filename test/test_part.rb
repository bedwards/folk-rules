require_relative "test_helper"
require "folk_rules/part"
require "folk_rules/musical_context"
require "folk_rules/note"

class TestPart < Minitest::Test
  def test_resolve_context_no_overrides
    ctx = FolkRules::MusicalContext.new(key: :c, scale: :major)
    part = FolkRules::Part.new(name: :test, type: :melody, bus: :pitched)
    assert_equal :c, part.resolve_context(ctx).key
  end

  def test_resolve_context_with_overrides
    ctx = FolkRules::MusicalContext.new(key: :bb, scale: :major)
    part = FolkRules::Part.new(
      name: :fiddle, type: :melody, bus: :pitched,
      context_overrides: {key: :g, scale: :minor_pentatonic}
    )
    resolved = part.resolve_context(ctx)
    assert_equal :g, resolved.key
    assert_equal :minor_pentatonic, resolved.scale
    # Original unchanged
    assert_equal :bb, ctx.key
  end

  def test_generate_with_octave_shift
    gen = ->(_ctx, _beat, _bar) {
      [FolkRules::Part::NoteEvent.new(note: 60, velocity: 100, duration: 1.0, channel: 0)]
    }
    part = FolkRules::Part.new(name: :test, type: :melody, bus: :pitched,
      octave_shift: 12, generator: gen)
    ctx = FolkRules::MusicalContext.new
    events = part.generate(ctx, beat: 1, bar: 1)
    assert_equal 72, events.first.note # 60 + 12
  end
end
