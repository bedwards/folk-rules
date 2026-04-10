require_relative "test_helper"
require "folk_rules/clock"

class TestClock < Minitest::Test
  # Deterministic time source we can step by hand.
  class FakeClock
    attr_accessor :t
    def initialize = (@t = 0.0)
    def call = @t
  end

  def setup
    @time = FakeClock.new
    @clock = FolkRules::Clock.new(now: @time, window: 96, beats_per_bar: 4)
  end

  def pump_ticks(count, dt:)
    count.times do
      @clock.handle(FolkRules::Clock::CLOCK)
      @time.t += dt
    end
  end

  def test_initial_state_has_no_bpm
    assert_nil @clock.bpm
    assert_equal 0, @clock.beat_count
    refute @clock.running?
  end

  def test_start_marks_running_and_fires_callback
    hits = 0
    @clock.on_start { hits += 1 }
    @clock.handle(FolkRules::Clock::START)
    assert @clock.running?
    assert_equal 1, hits
  end

  def test_stop_clears_running
    @clock.handle(FolkRules::Clock::START)
    @clock.handle(FolkRules::Clock::STOP)
    refute @clock.running?
  end

  def test_smoother_locks_to_120_bpm_within_tolerance
    # 120 BPM at 24 PPQN → 20.833... ms per tick.
    dt = 60.0 / (120 * FolkRules::Clock::PPQN)
    # Feed two full beats then check bpm.
    @clock.handle(FolkRules::Clock::START)
    pump_ticks(48, dt: dt)
    assert_in_delta 120.0, @clock.bpm, 0.01
  end

  def test_smoother_locks_to_140_bpm
    dt = 60.0 / (140 * FolkRules::Clock::PPQN)
    @clock.handle(FolkRules::Clock::START)
    pump_ticks(96, dt: dt)
    assert_in_delta 140.0, @clock.bpm, 0.01
  end

  def test_beat_callback_fires_every_24_ticks
    beats = []
    @clock.on_beat { |n| beats << n }
    @clock.handle(FolkRules::Clock::START)
    pump_ticks(72, dt: 0.001)
    assert_equal [1, 2, 3], beats
    assert_equal 3, @clock.beat_count
  end

  def test_bar_callback_fires_every_4_beats
    bars = []
    @clock.on_bar { |n| bars << n }
    @clock.handle(FolkRules::Clock::START)
    pump_ticks(24 * 8, dt: 0.001)
    assert_equal [1, 2], bars
    assert_equal 2, @clock.bar_count
  end

  def test_start_resets_counters
    @clock.handle(FolkRules::Clock::START)
    pump_ticks(50, dt: 0.001)
    assert @clock.beat_count > 0
    @clock.handle(FolkRules::Clock::START)
    assert_equal 0, @clock.beat_count
    assert_equal 0, @clock.bar_count
  end

  def test_smoother_window_bounds
    dt = 60.0 / (100 * FolkRules::Clock::PPQN)
    pump_ticks(500, dt: dt)
    assert_in_delta 100.0, @clock.bpm, 0.01
  end

  def test_tempo_change_converges
    dt_fast = 60.0 / (160 * FolkRules::Clock::PPQN)
    dt_slow = 60.0 / (80 * FolkRules::Clock::PPQN)
    pump_ticks(96, dt: dt_fast)
    assert_in_delta 160.0, @clock.bpm, 0.01
    pump_ticks(96, dt: dt_slow)
    # After a full window of new timing, we should be locked to the new tempo.
    assert_in_delta 80.0, @clock.bpm, 0.01
  end
end
