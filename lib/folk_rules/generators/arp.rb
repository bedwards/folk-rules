module FolkRules
  module Generators
    # Arpeggiator: plays chord tones one at a time in a configurable pattern.
    # Modes: :up, :down, :updown, :random.
    class Arp
      DEFAULT_OCTAVE = 3
      DEFAULT_VELOCITY = 85
      DEFAULT_DURATION = 0.5

      CHORD_INTERVALS = {
        major: [0, 4, 7],
        minor: [0, 3, 7],
        seventh: [0, 4, 7, 10],
        minor_seventh: [0, 3, 7, 10]
      }.freeze

      def initialize(octave: DEFAULT_OCTAVE, velocity: DEFAULT_VELOCITY,
        mode: :up, voicing: :major, octave_range: 1,
        pattern: "x.x.x.x.x.x.x.x.")
        @octave = octave
        @velocity = velocity
        @mode = mode
        @voicing = voicing
        @octave_range = octave_range
        @pattern = pattern
        @position = 0
        @direction = 1
      end

      def call(context, beat, _bar)
        steps = @pattern.chars
        step_idx = ((beat - 1) * (steps.length / context.beats_per_bar)) % steps.length
        return [] unless %w[x X o].include?(steps[step_idx])

        chord = context.current_chord
        return [] unless chord

        root_pc = FolkRules::Note.to_midi("#{chord}0") % 12
        intervals = CHORD_INTERVALS.fetch(@voicing, CHORD_INTERVALS[:major])

        # Build note pool across octave range.
        pool = []
        @octave_range.times do |oct|
          base = (@octave + 1 + oct) * 12 + root_pc
          intervals.each { |i| pool << (base + i) }
        end

        return [] if pool.empty?
        note = pool[@position % pool.length]
        advance!(pool.length)

        vel = case steps[step_idx]
        when "X" then 120
        when "o" then 60
        else @velocity
        end

        [Part::NoteEvent.new(note: note, velocity: vel, duration: DEFAULT_DURATION, channel: 0)]
      end

      private

      def advance!(pool_size)
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
          @position = rand(pool_size)
        end
      end
    end
  end
end
