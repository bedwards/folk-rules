module FolkRules
  module Modules
    # NoteRepeat: repeats each incoming note N times with configurable
    # velocity decay. Used for drum rolls, fills, and ratchet effects.
    class NoteRepeat < Base
      def initialize(repeats: 3, decay: 0.8)
        @repeats = repeats
        @decay = decay
      end

      def process(events, _context, beat: 0, bar: 0)
        events.flat_map do |event|
          repeat_note(event)
        end
      end

      private

      def repeat_note(event)
        vel = event.velocity.to_f
        duration_each = event.duration / @repeats

        @repeats.times.map do |i|
          v = [vel.round, 1].max
          result = FolkRules::Part::NoteEvent.new(
            note: event.note,
            velocity: [v, 127].min,
            duration: duration_each,
            channel: event.channel
          )
          vel *= @decay
          result
        end
      end
    end
  end
end
