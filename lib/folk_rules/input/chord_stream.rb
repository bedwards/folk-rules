module FolkRules
  module Input
    # ChordStream: reads MIDI notes from an input bus and identifies the
    # currently held chord. Exposes current_chord and on_chord_change callbacks.
    #
    # Can be used as a progression source for MusicalContext instead of a
    # static array — songs can receive live chord changes from Bitwig.
    #
    # For testing, accepts a FakeInput that yields synthetic note-on/off.
    class ChordStream
      CHORD_QUALITIES = {
        [0, 4, 7] => :major,
        [0, 3, 7] => :minor,
        [0, 4, 7, 10] => :seventh,
        [0, 3, 7, 10] => :minor_seventh,
        [0, 4, 7, 11] => :major_seventh,
        [0, 5, 7] => :sus4,
        [0, 2, 7] => :sus2,
        [0, 3, 6] => :diminished,
        [0, 4, 8] => :augmented,
        [0, 7] => :power
      }.freeze

      attr_reader :current_chord, :held_notes, :history

      def initialize(max_history: 32)
        @held_notes = []
        @current_chord = nil
        @history = []
        @max_history = max_history
        @callbacks = []
        @mutex = Mutex.new
      end

      def on_chord_change(&blk)
        @callbacks << blk
        self
      end

      # Feed a MIDI message (status byte + data).
      # Handles note-on (0x90) and note-off (0x80 or velocity 0).
      def handle(status, data1 = 0, data2 = 0)
        type = status & 0xF0
        case type
        when 0x90
          if data2 > 0
            note_on(data1)
          else
            note_off(data1)
          end
        when 0x80
          note_off(data1)
        end
      end

      # Attach to a Midi::Input (or any object responding to on_message).
      def attach(input)
        input.on_message { |status, *data| handle(status, *data) }
        self
      end

      # For simulated/test use: feed an array of [status, d1, d2] messages.
      def feed(messages)
        messages.each { |msg| handle(*msg) }
        self
      end

      private

      def note_on(note)
        old_chord = nil
        new_chord = nil
        @mutex.synchronize do
          @held_notes << note unless @held_notes.include?(note)
          @held_notes.sort!
          old_chord = @current_chord
          @current_chord = identify_chord(@held_notes)
          new_chord = @current_chord
        end
        if new_chord && new_chord != old_chord
          @history << new_chord
          @history.shift while @history.size > @max_history
          @callbacks.each { |cb| cb.call(new_chord) }
        end
      end

      def note_off(note)
        @mutex.synchronize do
          @held_notes.delete(note)
          @current_chord = identify_chord(@held_notes) if @held_notes.any?
        end
      end

      def identify_chord(notes)
        return nil if notes.size < 2

        # Normalize to pitch classes relative to lowest note
        root = notes.min
        root_pc = root % 12
        pcs = notes.map { |n| (n % 12 - root_pc) % 12 }.uniq.sort

        quality = CHORD_QUALITIES[pcs]
        root_name = FolkRules::Note::NAMES[root_pc]

        if quality
          {root: root_name.to_sym, quality: quality, bass_note: root}
        else
          {root: root_name.to_sym, quality: :unknown, intervals: pcs, bass_note: root}
        end
      end
    end
  end
end
