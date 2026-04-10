# 05_humanize_demo.rb — Demonstrates humanize, multi-note, note-length, and
# note-filter modules. Bb major progression with per-module scale override
# (G minor pentatonic melody) confirming D9 still works with the new modules.
require "folk_rules"

FolkRules.song "05_humanize_demo" do
  context_set key: :bb, scale: :major, beats_per_bar: 4,
    progression: [:bb, :eb, :f, :bb]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end

  # Bass with humanized velocity for a live upright feel
  bass :upright, bus: :pitched, channel: 0,
    octave: 2, pattern: "x...x...x...x...",
    modules: [FolkRules::Modules::Humanize.new(velocity: 0.15, seed: 1)]

  # Chord with staccato note length — rhythm guitar chops
  chord :rhythm_gtr, bus: :pitched, channel: 1,
    octave: 3, voicing: :major, pattern: "x...x...x...x...",
    modules: [FolkRules::Modules::NoteLength.new(mode: :staccato)]

  # Melody in G minor pentatonic with octave doubling + humanize
  melody :fiddle, bus: :pitched, channel: 2,
    octave: 4, scale: [:g, :minor_pentatonic],
    pattern: "x...x.x...x.x...",
    modules: [
      FolkRules::Modules::MultiNote.new(intervals: [12]),
      FolkRules::Modules::Humanize.new(velocity: 0.1, seed: 2)
    ]
end
