module FolkRules
  module Generators
    # Simple bass generator: plays the root of the current chord on beat 1,
    # with optional passing tones. Minimal v0.3 implementation — just root
    # notes from the progression on every beat, octave configurable.
    class Bass
      DEFAULT_OCTAVE = 2 # C2 = MIDI 36..48 range
      DEFAULT_VELOCITY = 90
      DEFAULT_DURATION = 0.9

      def initialize(octave: DEFAULT_OCTAVE, velocity: DEFAULT_VELOCITY, pattern: nil)
        @octave = octave
        @velocity = velocity
        @pattern = pattern || "x...x...x...x..."
      end

      def call(context, beat, _bar)
        chord = context.current_chord
        return [] unless chord

        root_pc = FolkRules::Note.to_midi("#{chord}0") % 12
        root_note = (@octave + 1) * 12 + root_pc

        steps = @pattern.chars
        step_idx = ((beat - 1) * (steps.length / context.beats_per_bar)) % steps.length
        return [] unless steps[step_idx] == "x" || steps[step_idx] == "X"

        vel = (steps[step_idx] == "X") ? 120 : @velocity
        [Part::NoteEvent.new(note: root_note, velocity: vel, duration: DEFAULT_DURATION, channel: 0)]
      end
    end
  end
end
