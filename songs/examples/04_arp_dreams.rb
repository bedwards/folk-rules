# 04_arp_dreams.rb — chord progression arpeggiated through a module chain.
# Demonstrates composable modules: Chord generator → Arpeggiator module.
require "folk_rules"

FolkRules.song "04_arp_dreams" do
  context_set key: :c, scale: :major, beats_per_bar: 4,
    progression: [:c, :am, :f, :g]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end

  bass :acoustic_bass, bus: :pitched, channel: 0,
    octave: 2, pattern: "x...x...x...x..."

  # Chord with arpeggiator module — plays one chord tone at a time
  chord :piano_arp, bus: :pitched, channel: 1,
    octave: 4, voicing: :major, pattern: "xxxx",
    modules: [FolkRules::Modules::Arpeggiator.new(mode: :up)]

  # Melody with note repeat for a shimmery effect
  melody :lead_shimmer, bus: :pitched, channel: 2,
    octave: 5, pattern: "x...x...",
    modules: [FolkRules::Modules::NoteRepeat.new(repeats: 3, decay: 0.7)]
end
