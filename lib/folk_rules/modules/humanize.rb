module FolkRules
  module Modules
    # Humanize: adds controlled randomness to velocity, timing offset, and
    # pitch to make parts feel less mechanical.
    #
    # Each parameter is an amount (0.0 = none, 1.0 = full range).
    # A seed can be pinned for reproducible results in tests/verify.
    class Humanize < Base
      def initialize(velocity: 0.1, timing: 0.0, pitch: 0.0, seed: nil)
        @velocity_amount = velocity
        @timing_amount = timing
        @pitch_amount = pitch
        @rng = seed ? Random.new(seed) : Random.new
      end

      def process(events, _context, beat: 0, bar: 0)
        events.map { |e| humanize_event(e) }
      end

      private

      def humanize_event(event)
        vel = event.velocity
        if @velocity_amount > 0
          range = (127 * @velocity_amount).round
          vel += @rng.rand(-range..range)
          vel = vel.clamp(1, 127)
        end

        note = event.note
        if @pitch_amount > 0
          range = (12 * @pitch_amount).round
          note += @rng.rand(-range..range)
          note = note.clamp(0, 127)
        end

        FolkRules::Part::NoteEvent.new(
          note: note,
          velocity: vel,
          duration: event.duration,
          channel: event.channel
        )
      end
    end
  end
end
