module FolkRules
  module Generators
    # Simple melody generator: walks the scale with configurable step size,
    # direction, and rhythmic pattern. Minimal v0.3: sequential scale walk
    # with wrap-around.
    class Melody
      DEFAULT_OCTAVE = 4
      DEFAULT_VELOCITY = 95
      DEFAULT_DURATION = 0.8

      def initialize(octave: DEFAULT_OCTAVE, velocity: DEFAULT_VELOCITY,
        pattern: "x...x...x...x...", step_size: 1, direction: :up)
        @octave = octave
        @velocity = velocity
        @pattern = pattern
        @step_size = step_size
        @direction = direction
        @position = 0
      end

      def call(context, beat, _bar)
        steps = @pattern.chars
        step_idx = ((beat - 1) * (steps.length / context.beats_per_bar)) % steps.length
        return [] unless %w[x X o].include?(steps[step_idx])

        notes = FolkRules::Note.scale_notes(
          "#{context.key}#{@octave}",
          context.scale,
          range: ((@octave + 1) * 12..((@octave + 2) * 12))
        )
        return [] if notes.empty?

        note = notes[@position % notes.length]
        advance!

        vel = case steps[step_idx]
        when "X" then 120
        when "o" then 60
        else @velocity
        end

        [Part::NoteEvent.new(note: note, velocity: vel, duration: DEFAULT_DURATION, channel: 0)]
      end

      private

      def advance!
        case @direction
        when :up then @position += @step_size
        when :down then @position -= @step_size
        when :updown
          @position += @step_size
          @direction = :downup_return if @position >= 7
        when :downup_return
          @position -= @step_size
          @direction = :up if @position <= 0
        end
      end
    end
  end
end
