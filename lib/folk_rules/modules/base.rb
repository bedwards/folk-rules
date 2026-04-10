module FolkRules
  module Modules
    # Base class for composable note-processing modules.
    # Each module transforms an array of NoteEvents into a (possibly different)
    # array of NoteEvents. Modules chain: part → module1 → module2 → output.
    #
    # Subclasses implement `process(events, context, beat:, bar:) -> [NoteEvent]`.
    class Base
      def process(events, _context, beat: 0, bar: 0)
        events
      end
    end
  end
end
