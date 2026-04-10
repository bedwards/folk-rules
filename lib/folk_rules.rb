require_relative "folk_rules/version"

# folk-rules — a pure-Ruby realtime MIDI framework for macOS.
#
# See CLAUDE.md and ~/.claude memory for the locked architecture (D1-D12).
module FolkRules
  class Error < StandardError; end

  autoload :CLI, "folk_rules/cli"
  autoload :Doctor, "folk_rules/doctor"
  autoload :Clock, "folk_rules/clock"
  autoload :Note, "folk_rules/note"
  autoload :MusicalContext, "folk_rules/musical_context"
  autoload :DrumPattern, "folk_rules/drum_pattern"
  autoload :Part, "folk_rules/part"
  autoload :Song, "folk_rules/song"
  autoload :Scheduler, "folk_rules/scheduler"
  autoload :MemoryOutput, "folk_rules/memory_output"
  autoload :Verifier, "folk_rules/verifier"

  module Input
    autoload :ChordStream, "folk_rules/input/chord_stream"
  end

  module Midi
    autoload :Input, "folk_rules/midi/input"
    autoload :Output, "folk_rules/midi/output"
  end

  module Modules
    autoload :Base, "folk_rules/modules/base"
    autoload :Arpeggiator, "folk_rules/modules/arpeggiator"
    autoload :ChordExpand, "folk_rules/modules/chord_expand"
    autoload :NoteRepeat, "folk_rules/modules/note_repeat"
    autoload :Humanize, "folk_rules/modules/humanize"
    autoload :MultiNote, "folk_rules/modules/multi_note"
    autoload :NoteLength, "folk_rules/modules/note_length"
    autoload :NoteFilter, "folk_rules/modules/note_filter"
    autoload :NoteLatch, "folk_rules/modules/note_latch"
    autoload :Fill, "folk_rules/modules/fill"
    autoload :PitchBend, "folk_rules/modules/pitch_bend"
  end

  module Generators
    autoload :Bass, "folk_rules/generators/bass"
    autoload :Chord, "folk_rules/generators/chord"
    autoload :Melody, "folk_rules/generators/melody"
    autoload :Arp, "folk_rules/generators/arp"
  end

  autoload :CcLfo, "folk_rules/cc_lfo"

  def self.song(name = "untitled", &block)
    Song.new(name, &block)
  end
end
