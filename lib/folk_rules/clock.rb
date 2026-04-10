module FolkRules
  # Pure-Ruby realtime MIDI clock reader.
  #
  # Consumes MIDI System Realtime messages (F8 tick, FA start, FB continue,
  # FC stop) from an injectable input and exposes a smoothed BPM, beat count,
  # bar count, and a callback API. No Sonic Pi, no separate process, no OSC.
  #
  # The smoother is a sliding-window average over the most recent N ticks
  # (default 96 = 4 quarter notes at 24 PPQN). This gives sub-0.1-BPM
  # accuracy against a stable source while rejecting single-tick jitter.
  #
  # Inputs are dependency-injected so tests can drive ticks synthetically
  # without touching CoreMIDI. The production input (FolkRules::Midi::Input)
  # wraps unimidi and delivers bytes on a dedicated thread.
  class Clock
    CLOCK = 0xF8
    START = 0xFA
    CONTINUE = 0xFB
    STOP = 0xFC
    SPP = 0xF2

    PPQN = 24

    attr_reader :bpm, :beat_count, :bar_count, :tick_count

    # @param window [Integer] number of ticks in the BPM smoothing window
    # @param beats_per_bar [Integer] musical bar length in beats
    # @param now [#call] monotonic time source (seconds, Float) — injectable
    def initialize(window: 96, beats_per_bar: 4, now: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @window = window
      @beats_per_bar = beats_per_bar
      @now = now
      @mutex = Mutex.new
      @callbacks = Hash.new { |h, k| h[k] = [] }
      reset_counters
    end

    def on_tick(&b) = (@callbacks[:tick] << b
                       self)

    def on_beat(&b) = (@callbacks[:beat] << b
                       self)

    def on_bar(&b) = (@callbacks[:bar] << b
                      self)

    def on_start(&b) = (@callbacks[:start] << b
                        self)

    def on_stop(&b) = (@callbacks[:stop] << b
                       self)

    def running? = @running

    # Feed a raw MIDI status byte. Data bytes (for SPP) are accepted but
    # currently unused; wiring them up is an M2 task when we resume-from-SPP.
    def handle(status, *_data)
      case status
      when CLOCK then tick!
      when START then start!
      when CONTINUE then continue!
      when STOP then stop!
      end
    end

    # Attach an input that yields status bytes via `#on_message(&block)`.
    # The input owns its own thread; Clock only receives callbacks.
    def attach(input)
      input.on_message { |status, *data| handle(status, *data) }
      self
    end

    private

    def reset_counters
      @tick_times = []
      @bpm = nil
      @tick_count = 0
      @beat_count = 0
      @bar_count = 0
      @tick_in_beat = 0
      @running = false
    end

    def tick!
      fire = nil
      bar_fire = nil
      @mutex.synchronize do
        t = @now.call
        @tick_times << t
        @tick_times.shift while @tick_times.size > @window
        if @tick_times.size >= 2
          span = @tick_times.last - @tick_times.first
          intervals = @tick_times.size - 1
          mean_dt = span / intervals
          @bpm = 60.0 / (mean_dt * PPQN) if mean_dt > 0
        end
        @tick_count += 1
        @tick_in_beat += 1
        if @tick_in_beat >= PPQN
          @tick_in_beat = 0
          @beat_count += 1
          fire = @beat_count
          if (@beat_count - 1) % @beats_per_bar == 0
            @bar_count += 1
            bar_fire = @bar_count
          end
        end
      end
      @callbacks[:tick].each { |cb| cb.call(@tick_count) }
      @callbacks[:beat].each { |cb| cb.call(fire) } if fire
      @callbacks[:bar].each { |cb| cb.call(bar_fire) } if bar_fire
    end

    def start!
      @mutex.synchronize do
        reset_counters
        @running = true
      end
      @callbacks[:start].each(&:call)
    end

    def continue!
      @mutex.synchronize { @running = true }
      @callbacks[:start].each(&:call)
    end

    def stop!
      @mutex.synchronize { @running = false }
      @callbacks[:stop].each(&:call)
    end
  end
end
