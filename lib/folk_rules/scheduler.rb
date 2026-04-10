module FolkRules
  # Subscribes to Clock callbacks and emits MIDI events to outputs.
  # Handles drum patterns (step-sequencing) and pitched parts (generator-based).
  #
  # Modes:
  #   :live — real Clock + real Midi::Output (production)
  #   :simulated — fake Clock driven by Scheduler itself + MemoryOutput (verify/test)
  class Scheduler
    MidiEvent = Data.define(:tick, :beat, :bar, :channel, :note, :velocity, :duration_steps, :bus)

    attr_reader :events, :tick_count

    def initialize(song:, clock: nil, outputs: {})
      @song = song
      @clock = clock
      @outputs = outputs # { bus_name: output }
      @events = []
      @tick_count = 0
      @step_count = 0
      @bar_count = 0
      @current_beat = 0
    end

    # Run in simulated mode: pump N bars through a fake clock.
    def simulate(bars:)
      steps_per_bar = @song.context.subdivision
      ticks_per_step = FolkRules::Clock::PPQN * @song.context.beats_per_bar / steps_per_bar
      total_ticks = bars * steps_per_bar * ticks_per_step

      @clock ||= FolkRules::Clock.new(beats_per_bar: @song.context.beats_per_bar)
      wire_clock!
      @clock.handle(FolkRules::Clock::START)
      total_ticks.times { @clock.handle(FolkRules::Clock::CLOCK) }
      @events
    end

    def start_live!
      wire_clock!
      self
    end

    private

    def wire_clock!
      steps_per_bar = @song.context.subdivision
      ticks_per_step = FolkRules::Clock::PPQN * @song.context.beats_per_bar / steps_per_bar

      tick_acc = 0
      @clock.on_tick do |_|
        @tick_count += 1
        tick_acc += 1
        if tick_acc >= ticks_per_step
          tick_acc = 0
          step!
        end
      end

      @clock.on_beat do |beat|
        @current_beat = beat
        emit_pitched_parts(beat)
      end

      @clock.on_bar do |bar|
        @bar_count = bar
        @song.context.advance_chord!
      end

      @clock.on_start do
        @step_count = 0
        @bar_count = 0
        @current_beat = 0
        tick_acc = 0
      end
    end

    def step!
      emit_drum_hits(@step_count)
      @step_count += 1
    end

    def emit_drum_hits(step)
      @song.drum_parts.each do |part|
        part.patterns.each do |dp|
          idx = step % dp.length
          vel = dp.steps[idx]
          next unless vel

          evt = MidiEvent.new(
            tick: @tick_count, beat: @clock.beat_count, bar: @bar_count,
            channel: part.channel, note: dp.note + (part.octave_shift || 0),
            velocity: vel, duration_steps: 1, bus: part.bus
          )
          @events << evt
          emit_midi(evt)
        end
      end
    end

    def emit_pitched_parts(beat)
      @song.pitched_parts.each do |part|
        note_events = part.generate(@song.context, beat: beat, bar: @bar_count)
        note_events.each do |ne|
          evt = MidiEvent.new(
            tick: @tick_count, beat: beat, bar: @bar_count,
            channel: ne.channel, note: ne.note,
            velocity: ne.velocity, duration_steps: 1, bus: part.bus
          )
          @events << evt
          emit_midi(evt)
        end
      end
    end

    def emit_midi(evt)
      out = @outputs[evt.bus]
      return unless out

      status_on = 0x90 | (evt.channel & 0x0F)
      out.puts(status_on, evt.note, evt.velocity)
    end
  end
end
