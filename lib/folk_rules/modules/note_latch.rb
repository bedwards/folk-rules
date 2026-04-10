module FolkRules
  module Modules
    # NoteLatch: holds the last received notes and re-emits them on subsequent
    # beats until new notes arrive. Useful for sustaining chords across beats
    # when the generator only fires on bar boundaries.
    class NoteLatch < Base
      def initialize
        @latched = []
      end

      def process(events, _context, beat: 0, bar: 0)
        if events.any?
          @latched = events.dup
          events
        else
          @latched
        end
      end
    end
  end
end
