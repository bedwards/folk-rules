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
      checks << check_cc_values_in_range(events)

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

    def note_events(events)
      events.select { |e| e.is_a?(Scheduler::MidiEvent) }
    end

    def cc_events(events)
      events.select { |e| e.is_a?(Scheduler::CcEvent) }
    end

    def check_drum_notes_valid(events)
      drum = note_events(events).select { |e| e.channel == 9 }
      bad = drum.reject { |e| (0..127).cover?(e.note) }
      Check.new(name: "drum_notes_valid", ok: bad.empty?, detail: "#{bad.size} out-of-range notes")
    end

    def check_pitched_notes_in_range(events)
      pitched = note_events(events).reject { |e| e.channel == 9 }
      bad = pitched.reject { |e| (0..127).cover?(e.note) }
      Check.new(name: "pitched_notes_in_range", ok: bad.empty?, detail: "#{pitched.size} pitched events, #{bad.size} out-of-range")
    end

    def check_velocities_in_range(events)
      bad = note_events(events).reject { |e| (1..127).cover?(e.velocity) }
      Check.new(name: "velocities_in_range", ok: bad.empty?, detail: "#{bad.size} out-of-range")
    end

    def check_cc_values_in_range(events)
      ccs = cc_events(events)
      bad = ccs.reject { |e| (0..127).cover?(e.value) }
      Check.new(name: "cc_values_in_range", ok: bad.empty?, detail: "#{ccs.size} CC events, #{bad.size} out-of-range")
    end
  end
end
