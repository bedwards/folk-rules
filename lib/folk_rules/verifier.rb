require_relative "song"
require_relative "scheduler"
require_relative "memory_output"
require_relative "clock"

module FolkRules
  # Runs a song in simulated mode and asserts basic MIDI correctness.
  # This is the engine behind `fr verify <song.rb>`.
  class Verifier
    Result = Data.define(:song_name, :bars, :events, :checks, :passed)
    Check = Data.define(:name, :ok, :detail)

    def initialize(song:, bars: 8)
      @song = song
      @bars = bars
    end

    def run
      output = MemoryOutput.new
      outputs = {}
      @song.buses.each_key { |name| outputs[name] = output }
      # If no buses declared, default a drums bus
      outputs[:drums] ||= output

      scheduler = Scheduler.new(song: @song, outputs: outputs)
      events = scheduler.simulate(bars: @bars)

      checks = []
      checks << check_has_events(events)
      checks << check_drum_notes_valid(events)
      checks << check_pitched_notes_in_range(events)
      checks << check_velocities_in_range(events)

      Result.new(
        song_name: @song.name,
        bars: @bars,
        events: events,
        checks: checks,
        passed: checks.all?(&:ok)
      )
    end

    private

    def check_has_events(events)
      Check.new(name: "has_events", ok: events.any?, detail: "#{events.size} events")
    end

    def check_drum_notes_valid(events)
      drum_events = events.select { |e| e.channel == 9 }
      bad = drum_events.reject { |e| (0..127).cover?(e.note) }
      Check.new(name: "drum_notes_valid", ok: bad.empty?, detail: "#{bad.size} out-of-range notes")
    end

    def check_pitched_notes_in_range(events)
      pitched = events.reject { |e| e.channel == 9 }
      bad = pitched.reject { |e| (0..127).cover?(e.note) }
      Check.new(name: "pitched_notes_in_range", ok: bad.empty?, detail: "#{pitched.size} pitched events, #{bad.size} out-of-range")
    end

    def check_velocities_in_range(events)
      bad = events.reject { |e| (1..127).cover?(e.velocity) }
      Check.new(name: "velocities_in_range", ok: bad.empty?, detail: "#{bad.size} out-of-range")
    end
  end
end
