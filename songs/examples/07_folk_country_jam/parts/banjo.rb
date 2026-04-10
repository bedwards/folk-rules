# Banjo: arpeggiated chord tones across 2 octaves, up-down pattern.
FOLK_JAM_BANJO = proc do
  chord :banjo, bus: :pitched, channel: 2,
    octave: 4, voicing: :major, pattern: "xxxxxxxxxxxx....",
    modules: [
      FolkRules::Modules::Arpeggiator.new(mode: :updown),
      FolkRules::Modules::NoteLength.new(mode: :gate, gate: 0.6),
      FolkRules::Modules::Humanize.new(velocity: 0.1, seed: 300)
    ]
end
