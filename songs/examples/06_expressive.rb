# 06_expressive.rb — Demonstrates fills, pitch bends, and CC modulation.
# G major folk progression with expressive modules on every part.
require "folk_rules"

FolkRules.song "06_expressive" do
  context_set key: :g, scale: :major, beats_per_bar: 4,
    progression: [:g, :c, :d, :g]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  # Drums with fills every 4 bars
  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end

  # Upright bass with humanize + occasional pitch slides
  bass :upright, bus: :pitched, channel: 0,
    octave: 2, pattern: "x...x...x...x...",
    modules: [
      FolkRules::Modules::Humanize.new(velocity: 0.15, seed: 1),
      FolkRules::Modules::PitchBend.new(amount: 1, direction: :up, probability: 0.2, seed: 2)
    ]

  # Rhythm guitar with staccato + fills on bar 4
  chord :rhythm_gtr, bus: :pitched, channel: 1,
    octave: 3, voicing: :major, pattern: "x...x...x...x...",
    modules: [
      FolkRules::Modules::NoteLength.new(mode: :staccato),
      FolkRules::Modules::Fill.new(every: 4, density: :light, seed: 3)
    ]

  # Banjo arp — chord tones arpeggiated with octave doubling
  chord :banjo, bus: :pitched, channel: 2,
    octave: 4, voicing: :major, pattern: "xxxx",
    modules: [
      FolkRules::Modules::Arpeggiator.new(mode: :updown),
      FolkRules::Modules::MultiNote.new(intervals: [12])
    ]

  # Fiddle melody with humanized velocity
  melody :fiddle, bus: :pitched, channel: 3,
    octave: 5, pattern: "x...x.x...x.x...",
    modules: [FolkRules::Modules::Humanize.new(velocity: 0.12, seed: 4)]

  # CC LFO: filter sweep on the pitched bus
  cc_lfo :filter_sweep, bus: :pitched, cc: 74, channel: 0,
    wave: :sine, rate: 0.5, min: 20, max: 110

  # CC LFO: expression swell on the fiddle channel
  cc_lfo :expression, bus: :pitched, cc: 11, channel: 3,
    wave: :triangle, rate: 1.0, min: 60, max: 127
end
