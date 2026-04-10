require_relative "musical_context"
require_relative "drum_pattern"
require_relative "part"

module FolkRules
  # DSL entrypoint. A song is defined with:
  #
  #   FolkRules.song "hello" do
  #     context_set key: :bb, scale: :major, progression: [:bb, :eb, :f, :bb]
  #     bus :drums, to: "folk_drums"
  #     bus :pitched, to: "folk_pitched"
  #
  #     drums :beat, bus: :drums do
  #       kick  "x...x...x...x..."
  #       snare "....x.......x..."
  #     end
  #
  #     bass :bass1, bus: :pitched, octave: 2
  #     chord :rhythm_gtr, bus: :pitched, voicing: :major
  #     melody :lead, bus: :pitched, scale: [:g, :minor_pentatonic]
  #     arp :mando, bus: :pitched, mode: :up, voicing: :major
  #   end
  class Song
    DrumPart = Data.define(:name, :bus, :channel, :octave_shift, :patterns)

    attr_reader :name, :context, :drum_parts, :pitched_parts, :buses

    def initialize(name, &block)
      @name = name
      @context = MusicalContext.new
      @drum_parts = []
      @pitched_parts = []
      @buses = {}
      instance_eval(&block) if block
    end

    # DSL: set musical context fields.
    def context_set(**opts)
      opts.each { |k, v| @context.send(:"#{k}=", v) }
    end

    # DSL: declare a bus.
    def bus(name, to: nil, channel: 0, octave_shift: 0)
      @buses[name] = {to: to, channel: channel, octave_shift: octave_shift}
    end

    # DSL: define a drum part.
    def drums(part_name, bus: :drums, channel: 9, octave_shift: nil, &block)
      bus_cfg = @buses[bus] || {}
      builder = DrumBuilder.new
      builder.instance_eval(&block)
      @drum_parts << DrumPart.new(
        name: part_name,
        bus: bus,
        channel: channel,
        octave_shift: octave_shift || bus_cfg[:octave_shift] || 0,
        patterns: builder.patterns
      )
    end

    # DSL: define a bass part.
    def bass(part_name, bus: :pitched, channel: 0, octave_shift: 0,
      octave: 2, velocity: 90, pattern: "x...x...x...x...", **overrides)
      require_relative "generators/bass"
      gen = Generators::Bass.new(octave: octave, velocity: velocity, pattern: pattern)
      add_pitched_part(part_name, :bass, bus, channel, octave_shift, gen, overrides)
    end

    # DSL: define a chord part.
    def chord(part_name, bus: :pitched, channel: 0, octave_shift: 0,
      octave: 3, velocity: 85, voicing: :major,
      pattern: "x...............", **overrides)
      require_relative "generators/chord"
      gen = Generators::Chord.new(octave: octave, velocity: velocity, voicing: voicing, pattern: pattern)
      add_pitched_part(part_name, :chord, bus, channel, octave_shift, gen, overrides)
    end

    # DSL: define a melody part.
    def melody(part_name, bus: :pitched, channel: 0, octave_shift: 0,
      octave: 4, velocity: 95, pattern: "x...x...x...x...",
      step_size: 1, direction: :up, scale: nil, **overrides)
      require_relative "generators/melody"
      if scale
        overrides[:key] = scale[0]
        overrides[:scale] = scale[1]
      end
      gen = Generators::Melody.new(octave: octave, velocity: velocity, pattern: pattern,
        step_size: step_size, direction: direction)
      add_pitched_part(part_name, :melody, bus, channel, octave_shift, gen, overrides)
    end

    # DSL: define an arp part.
    def arp(part_name, bus: :pitched, channel: 0, octave_shift: 0,
      octave: 3, velocity: 85, mode: :up, voicing: :major,
      octave_range: 1, pattern: "x.x.x.x.x.x.x.x.", **overrides)
      require_relative "generators/arp"
      gen = Generators::Arp.new(octave: octave, velocity: velocity, mode: mode,
        voicing: voicing, octave_range: octave_range, pattern: pattern)
      add_pitched_part(part_name, :arp, bus, channel, octave_shift, gen, overrides)
    end

    private

    def add_pitched_part(name, type, bus, channel, octave_shift, generator, context_overrides)
      bus_cfg = @buses[bus] || {}
      @pitched_parts << Part.new(
        name: name,
        type: type,
        bus: bus,
        channel: channel,
        octave_shift: octave_shift + (bus_cfg[:octave_shift] || 0),
        context_overrides: context_overrides,
        generator: generator
      )
    end
  end

  # Builder for drum patterns inside a `drums` block.
  class DrumBuilder
    attr_reader :patterns

    def initialize
      @patterns = []
    end

    def method_missing(name, pattern = nil, **opts, &block)
      if FolkRules::Note::DRUMS.key?(name)
        @patterns << DrumPattern.new(name: name, pattern: pattern, **opts)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      FolkRules::Note::DRUMS.key?(name) || super
    end
  end

  # Top-level DSL method.
  def self.song(name = "untitled", &block)
    Song.new(name, &block)
  end
end
