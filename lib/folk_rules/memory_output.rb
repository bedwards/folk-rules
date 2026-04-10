module FolkRules
  # A fake MIDI output that records all bytes for test assertions.
  # Quacks like Midi::Output (responds to #puts and #close).
  class MemoryOutput
    attr_reader :messages

    def initialize
      @messages = []
    end

    def puts(*bytes)
      @messages << bytes.flatten
    end

    def close = nil

    # Helper: extract note-on events as {note:, velocity:, channel:} hashes.
    def note_ons
      @messages.filter_map do |msg|
        next unless msg.length >= 3
        status = msg[0]
        next unless (status & 0xF0) == 0x90 && msg[2] > 0
        {channel: status & 0x0F, note: msg[1], velocity: msg[2]}
      end
    end
  end
end
