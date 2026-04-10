module FolkRules
  module Modules
    # MultiNote: stacks intervals above each incoming note.
    # Useful for octave doubling, fifths, or building custom voicings
    # from a single melodic line.
    class MultiNote < Base
      def initialize(intervals: [12])
        @intervals = intervals
      end

      def process(events, _context, beat: 0, bar: 0)
        events.flat_map do |event|
          [event] + @intervals.map do |interval|
            FolkRules::Part::NoteEvent.new(
              note: (event.note + interval).clamp(0, 127),
              velocity: event.velocity,
              duration: event.duration,
              channel: event.channel
            )
          end
        end
      end
    end
  end
end
