module FolkRules
  # A pitched musical part (bass, melody, chord, arp).
  # Each part has a type, local context overrides, a bus, a generator
  # that produces notes, and an optional chain of modules that transform them.
  #
  # Generators: ->(context, beat, bar) { [NoteEvent, ...] }
  # Modules: each responds to process(events, context, beat:, bar:) -> [NoteEvent]
  class Part
    NoteEvent = Data.define(:note, :velocity, :duration, :channel)

    attr_reader :name, :type, :bus, :channel, :octave_shift,
      :context_overrides, :generator, :modules

    def initialize(name:, type:, bus:, channel: 0, octave_shift: 0,
      context_overrides: {}, generator: nil, modules: [])
      @name = name
      @type = type
      @bus = bus
      @channel = channel
      @octave_shift = octave_shift
      @context_overrides = context_overrides
      @generator = generator
      @modules = modules
    end

    def resolve_context(song_context)
      return song_context if @context_overrides.empty?
      song_context.dup_with(**@context_overrides)
    end

    # Generate notes, then run through module chain, then apply octave shift.
    def generate(song_context, beat:, bar:)
      return [] unless @generator
      ctx = resolve_context(song_context)
      events = @generator.call(ctx, beat, bar)

      # Run through module chain
      @modules.each do |mod|
        events = mod.process(events, ctx, beat: beat, bar: bar)
      end

      # Apply octave shift and force channel
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
