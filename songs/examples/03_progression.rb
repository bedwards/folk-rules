# 03_progression.rb — Bb major progression with drums, bass, chords, arp, and
# a G minor pentatonic melody. Validates D9: per-module scale overrides coexist
# with the song-level key/scale.
require "folk_rules"

FolkRules.song "03_progression" do
  context_set key: :bb, scale: :major, beats_per_bar: 4,
    progression: [:bb, :eb, :f, :bb]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  drums :kit, bus: :drums, channel: 9 do
    kick "x...x...x...x..."
    snare "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end

  bass :upright, bus: :pitched, channel: 0,
    octave: 2, pattern: "x...x...x...x..."

  chord :rhythm_gtr, bus: :pitched, channel: 1,
    octave: 3, voicing: :major, pattern: "x...x...x...x..."

  arp :mandolin, bus: :pitched, channel: 2,
    octave: 4, mode: :up, voicing: :major, octave_range: 2,
    pattern: "x.x.x.x.x.x.x.x."

  melody :fiddle, bus: :pitched, channel: 3,
    octave: 4, scale: [:g, :minor_pentatonic],
    pattern: "x...x.x...x.x..."
end
