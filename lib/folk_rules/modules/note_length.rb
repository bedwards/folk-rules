module FolkRules
  module Modules
    # NoteLength: transforms note durations.
    # Modes: :legato (full duration), :staccato (short), :gate (percentage).
    class NoteLength < Base
      def initialize(mode: :gate, gate: 0.8)
        @mode = mode
        @gate = gate
      end

      def process(events, _context, beat: 0, bar: 0)
        events.map { |e| transform_length(e) }
      end

      private

      def transform_length(event)
        dur = case @mode
        when :legato then event.duration * 1.2
        when :staccato then event.duration * 0.3
        when :gate then event.duration * @gate
        else event.duration
        end

        FolkRules::Part::NoteEvent.new(
          note: event.note,
          velocity: event.velocity,
          duration: dur,
          channel: event.channel
        )
      end
    end
  end
end
