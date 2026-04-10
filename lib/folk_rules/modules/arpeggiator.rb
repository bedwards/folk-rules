module FolkRules
  module Modules
    # Arpeggiator module: takes a chord (multiple simultaneous notes) and
    # outputs one note at a time in a configurable pattern.
    #
    # Unlike Generators::Arp (which generates from context), this transforms
    # incoming note events — e.g., a chord part piped through an arpeggiator.
    class Arpeggiator < Base
      MODES = %i[up down updown random].freeze

      def initialize(mode: :up, rate: 1, gate: 0.5)
        @mode = mode
        @rate = rate # notes per beat (1 = quarter, 2 = eighth, 4 = sixteenth)
        @gate = gate
        @position = 0
        @direction = 1
      end

      def process(events, _context, beat: 0, bar: 0)
        return [] if events.empty?

        sorted = events.sort_by(&:note)
        note = pick_note(sorted)
        advance!(sorted.length)

        [FolkRules::Part::NoteEvent.new(
          note: note.note,
          velocity: note.velocity,
          duration: note.duration * @gate,
          channel: note.channel
        )]
      end

      private

      def pick_note(sorted)
        case @mode
        when :random
          sorted[rand(sorted.length)]
        else
          sorted[@position % sorted.length]
        end
      end

      def advance!(pool_size)
        return if pool_size == 0
        case @mode
        when :up
          @position = (@position + 1) % pool_size
        when :down
          @position = (@position - 1) % pool_size
        when :updown
          @position += @direction
          if @position >= pool_size - 1
            @direction = -1
          elsif @position <= 0
            @direction = 1
          end
        when :random
          nil # already random in pick_note
        end
      end
    end
  end
end
