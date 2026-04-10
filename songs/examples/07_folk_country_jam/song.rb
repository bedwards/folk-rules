# 07_folk_country_jam — Multi-file folk/alt-country production.
#
# Demonstrates: all generators, all modules, CC LFOs, multi-file layout,
# D9 per-module scale overrides, and the full DSL surface. This is the
# capstone example that exercises every feature of folk-rules.
#
# Instruments (targeting Bitwig acoustic samplers):
#   ch0  — Upright bass
#   ch1  — Acoustic guitar (rhythm)
#   ch2  — Banjo (arp)
#   ch3  — Mandolin (melody, Irish-style)
#   ch4  — Fiddle (counter-melody, blues minor)
#   ch5  — Organ (pad, latched chords)
#   ch9  — Drums
#
# Key: G major, but fiddle plays in G blues for a gritty edge.
# Progression: G - C - D - Em (classic folk/country)

require "folk_rules"
require_relative "parts/drums"
require_relative "parts/bass"
require_relative "parts/guitar"
require_relative "parts/banjo"
require_relative "parts/mandolin"
require_relative "parts/fiddle"
require_relative "parts/organ"

FolkRules.song "07_folk_country_jam" do
  context_set key: :g, scale: :major, beats_per_bar: 4,
    progression: [:g, :c, :d, :em]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  # Parts are defined in separate files for clean diffs
  instance_eval(&FOLK_JAM_DRUMS)
  instance_eval(&FOLK_JAM_BASS)
  instance_eval(&FOLK_JAM_GUITAR)
  instance_eval(&FOLK_JAM_BANJO)
  instance_eval(&FOLK_JAM_MANDOLIN)
  instance_eval(&FOLK_JAM_FIDDLE)
  instance_eval(&FOLK_JAM_ORGAN)

  # CC modulation
  cc_lfo :filter_sweep, bus: :pitched, cc: 74, channel: 0,
    wave: :sine, rate: 0.25, min: 30, max: 100

  cc_lfo :organ_swell, bus: :pitched, cc: 11, channel: 5,
    wave: :triangle, rate: 0.5, min: 50, max: 120

  cc_lfo :banjo_brightness, bus: :pitched, cc: 74, channel: 2,
    wave: :saw, rate: 1.0, min: 40, max: 127
end
