# Fiddle: counter-melody in G blues scale (D9 override — different from
# the song's G major). Note repeats for a gritty, ornamental feel.
FOLK_JAM_FIDDLE = proc do
  melody :fiddle, bus: :pitched, channel: 4,
    octave: 5, scale: [:g, :blues],
    pattern: "x.......x.......x.......",
    step_size: 2, direction: :updown,
    modules: [
      FolkRules::Modules::NoteRepeat.new(repeats: 2, decay: 0.7),
      FolkRules::Modules::Humanize.new(velocity: 0.15, seed: 500)
    ]
end
