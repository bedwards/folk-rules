module FolkRules
  # A pitched musical part (bass, melody, chord, arp).
  # Each part has a type, local context overrides, a bus, and a generator
  # that produces notes given the current musical context + beat position.
  #
  # Generators are simple callables: ->(context, beat, bar) { [NoteEvent, ...] }
  # Built-in generators ship in FolkRules::Generators::*.
  class Part
    NoteEvent = Data.define(:note, :velocity, :duration, :channel)

    attr_reader :name, :type, :bus, :channel, :octave_shift, :context_overrides, :generator

    def initialize(name:, type:, bus:, channel: 0, octave_shift: 0, context_overrides: {}, generator: nil)
      @name = name
      @type = type
      @bus = bus
      @channel = channel
      @octave_shift = octave_shift
      @context_overrides = context_overrides
      @generator = generator
    end

    # Resolve this part's effective context by overlaying overrides on the song context.
    def resolve_context(song_context)
      return song_context if @context_overrides.empty?
      song_context.dup_with(**@context_overrides)
    end

    # Generate notes for a given beat position.
    def generate(song_context, beat:, bar:)
      return [] unless @generator
      ctx = resolve_context(song_context)
      events = @generator.call(ctx, beat, bar)
      events.map do |e|
        NoteEvent.new(
          note: e.note + @octave_shift,
          velocity: e.velocity,
          duration: e.duration,
          channel: @channel
        )
      end
    end
  end
end
