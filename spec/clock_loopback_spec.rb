require "spec_helper"
require "folk_rules/clock"
require "folk_rules/midi/input"
require "folk_rules/midi/output"

# Loopback integration: pumps raw 0xF8 bytes into IAC `folk_clock` from a
# pure-Ruby "Bitwig simulator" thread and asserts the Clock class locks onto
# the target BPM.
#
# Gated on FOLK_RULES_IAC=1 — requires the three IAC buses to exist and no
# other process to be holding `folk_clock` (Bitwig should be closed during
# this spec).
RSpec.describe FolkRules::Clock, :iac do
  let(:target_bpm) { 123.0 }
  let(:tick_period) { 60.0 / (target_bpm * FolkRules::Clock::PPQN) }

  it "locks to the pumped BPM within 0.5 BPM after one window" do
    input = FolkRules::Midi::Input.new(match: "folk_clock").open.start
    output = FolkRules::Midi::Output.new(match: "folk_clock").open
    clock = FolkRules::Clock.new
    clock.attach(input)

    pumper = Thread.new do
      Thread.current.priority = 2
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      300.times do
        deadline += tick_period
        output.puts(FolkRules::Clock::CLOCK)
        delta = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        sleep(delta) if delta > 0
      end
    end
    pumper.join

    sleep 0.05 # drain
    expect(clock.bpm).not_to be_nil
    expect(clock.bpm).to be_within(0.5).of(target_bpm)
    expect(clock.beat_count).to be >= 10
  ensure
    input&.stop
    output&.close
  end
end
