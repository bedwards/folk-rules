require_relative "clock"
require_relative "scheduler"
require_relative "midi/input"
require_relative "midi/output"

module FolkRules
  # Live runner: wires Clock (from Bitwig via IAC) to Scheduler (to IAC outputs).
  # This is the engine behind `fr run <song.rb>`.
  #
  # Lifecycle:
  #   1. Opens MIDI input on folk_clock bus
  #   2. Opens MIDI outputs for each declared bus in the song
  #   3. Wires Clock → Scheduler with real outputs
  #   4. Starts clock input reader thread
  #   5. Blocks until Ctrl-C, printing status on each bar
  #   6. Cleans up all MIDI endpoints on exit
  class Runner
    def initialize(song:, clock_bus: "folk_clock")
      @song = song
      @clock_bus = clock_bus
      @clock_input = nil
      @clock = nil
      @scheduler = nil
      @outputs = {}
      @running = false
    end

    def run
      open_outputs!
      open_clock!
      wire!
      start!
      wait_for_shutdown!
    ensure
      shutdown!
    end

    private

    def open_outputs!
      @song.buses.each do |name, cfg|
        target = cfg[:to]
        next unless target
        begin
          out = Midi::Output.new(match: target).open
          @outputs[name] = out
          log "Output #{name} → #{out.name}"
        rescue => e
          warn "WARNING: could not open output #{name} (#{target}): #{e.message}"
        end
      end
    end

    def open_clock!
      @clock_input = Midi::Input.new(match: @clock_bus).open
      log "Clock input ← #{@clock_input.name}"
      @clock = Clock.new(beats_per_bar: @song.context.beats_per_bar)
    end

    def wire!
      @scheduler = Scheduler.new(song: @song, clock: @clock, outputs: @outputs)
      @scheduler.start_live!
      @clock.attach(@clock_input)

      @clock.on_start { log "\e[32m▶ START\e[0m" }
      @clock.on_stop { log "\e[31m■ STOP\e[0m" }
      @clock.on_bar do |bar|
        bpm_str = @clock.bpm ? format("%.1f", @clock.bpm) : "?"
        chord = @song.context.current_chord
        chord_str = chord ? chord.to_s : "—"
        log "bar=#{bar} bpm=#{bpm_str} chord=#{chord_str} events=#{@scheduler.events.size}"
      end
    end

    def start!
      @running = true
      @clock_input.start

      puts "\e[1mfolk-rules v#{VERSION}\e[0m — \e[36m#{@song.name}\e[0m"
      puts "Key: #{@song.context.key} #{@song.context.scale} | Beats/bar: #{@song.context.beats_per_bar}"
      puts "Outputs: #{@outputs.map { |k, v| "#{k}→#{v.name}" }.join(", ")}"
      puts "Clock: #{@clock_input.name}"
      puts
      puts "Waiting for Bitwig clock... (Ctrl-C to stop)"
      puts
    end

    def wait_for_shutdown!
      trap("INT") { @running = false }
      trap("TERM") { @running = false }
      sleep 0.1 while @running
    end

    def shutdown!
      log "Shutting down..."
      @clock_input&.stop
      @outputs.each_value(&:close)
      # Send all-notes-off on each output channel we used
      send_all_notes_off!
      log "Done."
    end

    def send_all_notes_off!
      channels_used = Set.new
      @song.drum_parts.each { |p| channels_used << p.channel }
      @song.pitched_parts.each { |p| channels_used << p.channel }

      @outputs.each_value do |out|
        channels_used.each do |ch|
          # CC 123 = All Notes Off
          out.puts(0xB0 | (ch & 0x0F), 123, 0)
        rescue
          nil
        end
      end
    rescue
      nil
    end

    def log(msg)
      puts "[#{Time.now.strftime("%H:%M:%S.%L")}] #{msg}"
    end
  end
end
