# Upright bass: root notes with humanized velocity and occasional slides.
FOLK_JAM_BASS = proc do
  bass :upright, bus: :pitched, channel: 0,
    octave: 2, pattern: "x...x...x...x...",
    modules: [
      FolkRules::Modules::Humanize.new(velocity: 0.12, seed: 100),
      FolkRules::Modules::PitchBend.new(amount: 1, direction: :up, probability: 0.15, seed: 101)
    ]
end
