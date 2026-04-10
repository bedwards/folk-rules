require_relative "musical_context"
require_relative "drum_pattern"

module FolkRules
  # DSL entrypoint. A song is defined with:
  #
  #   FolkRules.song "hello" do
  #     context key: :c, scale: :major, beats_per_bar: 4
  #     bus :drums, to: "folk_drums", octave_shift: 0
  #
  #     drums :beat1, bus: :drums do
  #       kick  "x...x...x...x..."
  #       snare "....x.......x..."
  #     end
  #   end
  class Song
    DrumPart = Data.define(:name, :bus, :channel, :octave_shift, :patterns)

    attr_reader :name, :context, :drum_parts, :buses

    def initialize(name, &block)
      @name = name
      @context = MusicalContext.new
      @drum_parts = []
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
  end

  # Builder for drum patterns inside a `drums` block.
  class DrumBuilder
    attr_reader :patterns

    def initialize
      @patterns = []
    end

    # Catch-all: any drum name method call creates a pattern.
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
