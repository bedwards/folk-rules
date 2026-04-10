require_relative "test_helper"
require "folk_rules/note"

class TestNote < Minitest::Test
  def test_c4_is_60
    assert_equal 60, FolkRules::Note.to_midi(:c4)
  end

  def test_c_minus1_is_0
    assert_equal 0, FolkRules::Note.to_midi("c-1")
  end

  def test_a4_is_69
    assert_equal 69, FolkRules::Note.to_midi(:a4)
  end

  def test_fs3_is_54
    assert_equal 54, FolkRules::Note.to_midi(:fs3)
  end

  def test_bb2_is_46
    assert_equal 46, FolkRules::Note.to_midi(:bb2)
  end

  def test_integer_passthrough
    assert_equal 42, FolkRules::Note.to_midi(42)
  end

  def test_scale_notes_c_major
    notes = FolkRules::Note.scale_notes(:c4, :major, range: 60..72)
    assert_equal [60, 62, 64, 65, 67, 69, 71, 72], notes
  end

  def test_in_scale_g_minor_pentatonic
    assert FolkRules::Note.in_scale?(55, :g3, :minor_pentatonic) # G
    assert FolkRules::Note.in_scale?(58, :g3, :minor_pentatonic) # Bb
    refute FolkRules::Note.in_scale?(56, :g3, :minor_pentatonic) # G#
  end

  def test_drums_kick_is_36
    assert_equal 36, FolkRules::Note::DRUMS[:kick]
  end
end
