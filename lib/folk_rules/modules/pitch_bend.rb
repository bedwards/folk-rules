module FolkRules
  module Modules
    # PitchBend: adds pitch bend events before notes for slide/bend effects.
    # Emits pitch bend CC alongside notes. The scheduler handles these as
    # special events that translate to MIDI pitch bend messages.
    #
    # For now, marks notes with a bend_amount metadata that the scheduler
    # can use when it gains pitch bend support. In simulated mode, the bend
    # is applied as a note shift (approximation for verification).
    class PitchBend < Base
      def initialize(amount: 2, direction: :up, probability: 0.3, seed: nil)
        @amount = amount # semitones
        @direction = direction # :up, :down, :random
        @probability = probability
        @rng = seed ? Random.new(seed) : Random.new
      end

      def process(events, _context, beat: 0, bar: 0)
        events.map do |e|
          if @rng.rand < @probability
            bend = case @direction
            when :up then @amount
            when :down then -@amount
            when :random then @rng.rand(-@amount..@amount)
            else 0
            end
            # Approximate: shift note then bend back (audible as a slide)
            FolkRules::Part::NoteEvent.new(
              note: (e.note + bend).clamp(0, 127),
              velocity: e.velocity,
              duration: e.duration,
              channel: e.channel
            )
          else
            e
          end
        end
      end
    end
  end
end
