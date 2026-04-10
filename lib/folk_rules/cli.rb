require "thor"
require_relative "doctor"
require_relative "clock"

module FolkRules
  # Subcommand group for clock introspection.
  class ClockCLI < Thor
    def self.exit_on_failure? = true

    desc "monitor", "Read the folk_clock IAC bus and print live BPM + beat + bar"
    method_option :bus, type: :string, default: "folk_clock"
    method_option :duration, type: :numeric, default: 0.0, desc: "stop after N seconds (0 = forever)"
    def monitor
      require_relative "midi/input"
      input = FolkRules::Midi::Input.new(match: options[:bus]).open
      clock = FolkRules::Clock.new
      clock.on_beat do |n|
        bpm = clock.bpm ? format("%6.2f", clock.bpm) : "  ? "
        puts "[#{Time.now.strftime("%H:%M:%S.%L")}] bar=#{clock.bar_count} beat=#{n} bpm=#{bpm}"
      end
      clock.attach(input)
      input.start
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      loop do
        sleep 0.1
        break if options[:duration] > 0 && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) >= options[:duration]
      end
    ensure
      input&.stop
    end
  end

  # Top-level `fr` command.
  class CLI < Thor
    def self.exit_on_failure? = true

    desc "version", "Print the folk-rules version"
    def version
      puts FolkRules::VERSION
    end

    desc "doctor", "Verify the dev environment (ruby, Sonic Pi, IAC buses, MIDI gems)"
    method_option :verbose, type: :boolean, default: false, aliases: "-v"
    def doctor
      ok = Doctor.new(verbose: options[:verbose]).run
      exit(ok ? 0 : 1)
    end

    desc "verify SONG_FILE", "Run a song in simulated mode and verify MIDI output"
    method_option :bars, type: :numeric, default: 8, desc: "number of bars to simulate"
    def verify(song_file)
      require_relative "verifier"
      song = load_song(song_file)
      result = Verifier.new(song: song, bars: options[:bars]).run
      result.checks.each do |c|
        mark = c.ok ? "\e[32m✓\e[0m" : "\e[31m✗\e[0m"
        puts "#{mark} #{c.name}: #{c.detail}"
      end
      puts
      puts "#{result.events.size} events over #{result.bars} bars"
      exit(result.passed ? 0 : 1)
    end

    desc "clock SUBCOMMAND", "Clock introspection commands"
    subcommand "clock", ClockCLI

    private

    def load_song(path)
      unless File.exist?(path)
        warn "song not found: #{path}"
        exit 1
      end
      # The song file is expected to call FolkRules.song and return the Song object.
      # We capture it by evaluating in a binding that returns the last expression.
      eval(File.read(path), TOPLEVEL_BINDING, path) # rubocop:disable Security/Eval
    end
  end
end
