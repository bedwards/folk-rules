module FolkRules
  module Generators
    # Chord voicing generator: plays the current chord as a block voicing
    # (root + third + fifth, optionally seventh) on configurable beats.
    class Chord
      INTERVALS = {
        major: [0, 4, 7],
        minor: [0, 3, 7],
        seventh: [0, 4, 7, 10],
        minor_seventh: [0, 3, 7, 10],
        major_seventh: [0, 4, 7, 11],
        sus4: [0, 5, 7],
        sus2: [0, 2, 7],
        diminished: [0, 3, 6],
        augmented: [0, 4, 8]
      }.freeze

      DEFAULT_OCTAVE = 3
      DEFAULT_VELOCITY = 85
      DEFAULT_DURATION = 0.95

      def initialize(octave: DEFAULT_OCTAVE, velocity: DEFAULT_VELOCITY,
        voicing: :major, pattern: "x...............") # hit once per bar
        @octave = octave
        @velocity = velocity
        @voicing = voicing
        @pattern = pattern
      end

      def call(context, beat, _bar)
        chord = context.current_chord
        return [] unless chord

        steps = @pattern.chars
        step_idx = ((beat - 1) * (steps.length / context.beats_per_bar)) % steps.length
        return [] unless %w[x X].include?(steps[step_idx])

        root_pc = FolkRules::Note.to_midi("#{chord}0") % 12
        root_midi = (@octave + 1) * 12 + root_pc
        intervals = INTERVALS.fetch(@voicing, INTERVALS[:major])

        intervals.map do |interval|
          Part::NoteEvent.new(
            note: root_midi + interval,
            velocity: @velocity,
            duration: DEFAULT_DURATION,
            channel: 0
          )
        end
      end
    end
  end
end
