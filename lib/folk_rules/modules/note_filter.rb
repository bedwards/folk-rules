module FolkRules
  module Modules
    # NoteFilter: passes only notes matching criteria.
    # Useful for splitting a chord into high/low ranges or filtering by velocity.
    class NoteFilter < Base
      def initialize(note_range: nil, velocity_range: nil, channel: nil)
        @note_range = note_range
        @velocity_range = velocity_range
        @channel = channel
      end

      def process(events, _context, beat: 0, bar: 0)
        events.select { |e| passes?(e) }
      end

      private

      def passes?(event)
        return false if @note_range && !@note_range.cover?(event.note)
        return false if @velocity_range && !@velocity_range.cover?(event.velocity)
        return false if @channel && event.channel != @channel
        true
      end
    end
  end
end
