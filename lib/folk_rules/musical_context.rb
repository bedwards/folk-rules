module FolkRules
  # Central musical state that all modules read from.
  # Written once in the song DSL; modules may override per-part.
  # See D9 in memory for the design rationale.
  class MusicalContext
    attr_accessor :key, :scale, :mode,
      :progression, :current_chord_index,
      :beats_per_bar, :subdivision, :feel

    def initialize(
      key: :c, scale: :major, mode: nil,
      progression: nil, beats_per_bar: 4,
      subdivision: 16, feel: :straight
    )
      @key = key
      @scale = scale
      @mode = mode
      @progression = progression || []
      @current_chord_index = 0
      @beats_per_bar = beats_per_bar
      @subdivision = subdivision
      @feel = feel
    end

    # The chord at the current position in the progression.
    # Returns nil if no progression is set.
    def current_chord
      return nil if @progression.empty?
      @progression[@current_chord_index % @progression.length]
    end

    # Advance to the next chord. Called on bar boundaries by the scheduler.
    def advance_chord!
      return if @progression.empty?
      @current_chord_index = (@current_chord_index + 1) % @progression.length
    end

    # Root note of the current key as a MIDI pitch class (0-11).
    def key_pc
      FolkRules::Note.to_midi("#{@key}0") % 12
    end

    # All MIDI notes in the current scale within a range.
    def scale_notes(range: 36..84)
      FolkRules::Note.scale_notes(@key.to_s + "0", @scale, range: range)
    end

    def dup_with(**overrides)
      ctx = dup
      overrides.each { |k, v| ctx.send(:"#{k}=", v) }
      ctx
    end
  end
end
