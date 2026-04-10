module FolkRules
  # Parses "x...x..." style drum patterns into step arrays.
  # Each character maps to one subdivision step:
  #   x  = hit (default velocity)
  #   X  = accent (high velocity)
  #   o  = ghost note (low velocity)
  #   .  = rest
  #   -  = rest (alias)
  class DrumPattern
    HIT_VELOCITY = 100
    ACCENT_VELOCITY = 127
    GHOST_VELOCITY = 50

    attr_reader :name, :note, :steps

    # @param name [Symbol] drum voice name (:kick, :snare, etc.)
    # @param pattern [String] pattern string
    # @param note [Integer] MIDI note number (from Note::DRUMS or explicit)
    # @param velocity [Integer, nil] override default velocity for all hits
    def initialize(name:, pattern:, note: nil, velocity: nil)
      @name = name
      @note = note || FolkRules::Note::DRUMS.fetch(name) { raise ArgumentError, "unknown drum: #{name}" }
      @velocity_override = velocity
      @steps = parse(pattern)
    end

    # Returns an array of {step:, velocity:} for non-rest steps.
    def hits
      @steps.each_with_index.filter_map do |vel, i|
        {step: i, velocity: vel} if vel
      end
    end

    def length = @steps.length

    private

    def parse(pattern)
      pattern.chars.map do |ch|
        case ch
        when "x" then @velocity_override || HIT_VELOCITY
        when "X" then @velocity_override || ACCENT_VELOCITY
        when "o" then @velocity_override || GHOST_VELOCITY
        when ".", "-" then nil
        else raise ArgumentError, "unknown pattern char: #{ch.inspect}"
        end
      end
    end
  end
end
