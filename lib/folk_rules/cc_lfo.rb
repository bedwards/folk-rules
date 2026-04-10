module FolkRules
  # CC LFO: generates MIDI CC modulation events on a configurable waveform.
  # Attaches to a bus and emits CC messages on each beat/tick.
  #
  # Used in the song DSL via:
  #   cc_lfo :filter_sweep, bus: :pitched, cc: 74, wave: :sine,
  #          rate: 0.25, min: 0, max: 127, channel: 0
  class CcLfo
    WAVES = %i[sine triangle saw ramp_up ramp_down square random].freeze

    attr_reader :name, :bus, :cc, :channel

    def initialize(name:, bus:, cc:, channel: 0, wave: :sine, rate: 1.0, min: 0, max: 127, seed: nil)
      @name = name
      @bus = bus
      @cc = cc
      @channel = channel
      @wave = wave
      @rate = rate # cycles per bar
      @min = min
      @max = max
      @rng = seed ? Random.new(seed) : Random.new
      @phase = 0.0
    end

    # Returns the CC value for a given beat position within a bar.
    # beat: 1-based beat number, beats_per_bar: time signature
    def value_at(beat:, beats_per_bar: 4)
      position = (beat - 1).to_f / beats_per_bar * @rate
      raw = waveform(position % 1.0)
      (@min + raw * (@max - @min)).round.clamp(0, 127)
    end

    private

    def waveform(phase)
      case @wave
      when :sine
        (Math.sin(phase * 2 * Math::PI) + 1) / 2
      when :triangle
        (phase < 0.5) ? phase * 2 : 2 - phase * 2
      when :saw, :ramp_up
        phase
      when :ramp_down
        1.0 - phase
      when :square
        (phase < 0.5) ? 1.0 : 0.0
      when :random
        @rng.rand
      else
        0.5
      end
    end
  end
end
