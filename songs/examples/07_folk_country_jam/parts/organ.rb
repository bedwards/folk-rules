# Organ: sustained pad chords with latching — holds each chord across beats.
# Expanded to seventh voicings for a rich gospel/country organ feel.
FOLK_JAM_ORGAN = proc do
  chord :organ, bus: :pitched, channel: 5,
    octave: 3, voicing: :major, pattern: "x...............",
    modules: [
      FolkRules::Modules::ChordExpand.new(voicing: :seventh),
      FolkRules::Modules::NoteLatch.new,
      FolkRules::Modules::NoteLength.new(mode: :legato)
    ]
end
