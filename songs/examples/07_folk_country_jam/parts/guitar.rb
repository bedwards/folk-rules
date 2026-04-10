# Acoustic guitar: staccato chord chops with bar-4 fills.
FOLK_JAM_GUITAR = proc do
  chord :rhythm_gtr, bus: :pitched, channel: 1,
    octave: 3, voicing: :major, pattern: "x...x...x...x...",
    modules: [
      FolkRules::Modules::NoteLength.new(mode: :staccato),
      FolkRules::Modules::Humanize.new(velocity: 0.08, seed: 200),
      FolkRules::Modules::Fill.new(every: 4, density: :light, seed: 201)
    ]
end
