module FolkRules
  # Note-name ↔ MIDI-number conversion and scale helpers.
  # Intentionally simple and dependency-free.
  module Note
    NAMES = %w[c cs d ds e f fs g gs a as b].freeze
    NAME_TO_PC = NAMES.each_with_index.to_h.freeze
    FLAT_MAP = {"db" => "cs", "eb" => "ds", "fb" => "e", "gb" => "fs",
                "ab" => "gs", "bb" => "as", "cb" => "b"}.freeze

    SCALES = {
      major: [0, 2, 4, 5, 7, 9, 11],
      minor: [0, 2, 3, 5, 7, 8, 10],
      minor_pentatonic: [0, 3, 5, 7, 10],
      major_pentatonic: [0, 2, 4, 7, 9],
      blues: [0, 3, 5, 6, 7, 10],
      dorian: [0, 2, 3, 5, 7, 9, 10],
      mixolydian: [0, 2, 4, 5, 7, 9, 10],
      lydian: [0, 2, 4, 6, 7, 9, 11],
      phrygian: [0, 1, 3, 5, 7, 8, 10],
      harmonic_minor: [0, 2, 3, 5, 7, 8, 11],
      melodic_minor: [0, 2, 3, 5, 7, 9, 11],
      chromatic: (0..11).to_a
    }.freeze

    # GM drum map — common names → MIDI note numbers.
    # Bitwig Drum Machine pads start at C1 = MIDI 36 (same as GM kick).
    DRUMS = {
      kick: 36, kick2: 35,
      snare: 38, snare2: 40, rimshot: 37, clap: 39,
      hat_closed: 42, hat_pedal: 44, hat_open: 46,
      tom_low: 45, tom_mid: 47, tom_hi: 50,
      crash: 49, crash2: 57, ride: 51, ride_bell: 53,
      tambourine: 54, cowbell: 56, shaker: 69,
      conga_hi: 62, conga_low: 64, bongo_hi: 60, bongo_low: 61
    }.freeze

    # Extract the root note name from a chord symbol.
    # :am → "a", :fsharp7 → "fs", :bb → "bb", :bbm → "bb", :c → "c"
    # Returns a string suitable for to_midi("#{root}0").
    def self.chord_root(chord_sym)
      s = chord_sym.to_s.downcase
      # Match root: one letter + optional sharp/flat suffix, before any quality
      if (m = s.match(/\A([a-g])([sb]?)/))
        root = m[1] + m[2]
        FLAT_MAP[root] || root

      else
        s[0] # fallback
      end
    end

    # Parse a note name like :c4, "Bb3", :fs2 → MIDI number.
    # Convention: C4 = 60 (middle C). Bitwig C1 = 36 = our C2 in SP terms
    # (but we use standard MIDI: C-1=0, C4=60).
    def self.to_midi(name)
      return name if name.is_a?(Integer)
      s = name.to_s.downcase.strip
      if (m = s.match(/\A([a-g][sb]?)(-?\d)\z/))
        pc_name = m[1].tr("s", "s") # keep "s" for sharp
        pc_name = FLAT_MAP[pc_name] || pc_name
        pc = NAME_TO_PC[pc_name]
        raise ArgumentError, "unknown note name: #{name}" unless pc
        octave = m[2].to_i
        (octave + 1) * 12 + pc
      else
        raise ArgumentError, "cannot parse note: #{name}"
      end
    end

    # Expand a scale from a root to a range of MIDI notes.
    # root: :c3 or 48, scale: :minor_pentatonic, range: 48..72
    def self.scale_notes(root, scale_name, range: nil)
      root_midi = to_midi(root)
      root_pc = root_midi % 12
      intervals = SCALES.fetch(scale_name) { raise ArgumentError, "unknown scale: #{scale_name}" }
      range ||= (root_midi..(root_midi + 24))
      range.select { |n| intervals.include?((n - root_pc) % 12) }
    end

    # Is a MIDI note in a given scale?
    def self.in_scale?(midi_note, root, scale_name)
      root_pc = to_midi(root) % 12
      intervals = SCALES.fetch(scale_name)
      intervals.include?((midi_note - root_pc) % 12)
    end
  end
end
