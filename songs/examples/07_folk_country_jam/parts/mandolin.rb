# Mandolin: Irish-style melody walking the G major scale.
# Octave doubling for that characteristic mandolin shimmer.
FOLK_JAM_MANDOLIN = proc do
  melody :mandolin, bus: :pitched, channel: 3,
    octave: 5, pattern: "x.x.x...x.x.x...",
    step_size: 1, direction: :up,
    modules: [
      FolkRules::Modules::MultiNote.new(intervals: [12]),
      FolkRules::Modules::Humanize.new(velocity: 0.1, seed: 400)
    ]
end
