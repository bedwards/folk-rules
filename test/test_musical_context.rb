require_relative "test_helper"
require "folk_rules/musical_context"
require "folk_rules/note"

class TestMusicalContext < Minitest::Test
  def test_defaults
    ctx = FolkRules::MusicalContext.new
    assert_equal :c, ctx.key
    assert_equal :major, ctx.scale
    assert_equal 4, ctx.beats_per_bar
    assert_equal 16, ctx.subdivision
    assert_equal :straight, ctx.feel
  end

  def test_progression_advance
    ctx = FolkRules::MusicalContext.new(
      key: :bb, scale: :major,
      progression: [:bb, :eb, :f, :bb]
    )
    assert_equal :bb, ctx.current_chord
    ctx.advance_chord!
    assert_equal :eb, ctx.current_chord
    ctx.advance_chord!
    assert_equal :f, ctx.current_chord
    ctx.advance_chord!
    assert_equal :bb, ctx.current_chord
    ctx.advance_chord!
    assert_equal :bb, ctx.current_chord # wraps
  end

  def test_key_pc
    ctx = FolkRules::MusicalContext.new(key: :g)
    assert_equal 7, ctx.key_pc # G = 7
  end

  def test_dup_with_override
    ctx = FolkRules::MusicalContext.new(key: :c, scale: :major)
    ctx2 = ctx.dup_with(scale: :minor_pentatonic, key: :g)
    assert_equal :g, ctx2.key
    assert_equal :minor_pentatonic, ctx2.scale
    assert_equal :c, ctx.key # original unchanged
  end
end
