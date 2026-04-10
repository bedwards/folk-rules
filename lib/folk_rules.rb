require_relative "folk_rules/version"

# folk-rules — a pure-Ruby realtime MIDI framework for macOS.
#
# See CLAUDE.md and ~/.claude memory/project_folk_rules*.md for the locked
# architecture (D1-D7). High-level surface:
#
#   FolkRules::Clock           — MIDI clock reader + smoother
#   FolkRules::Midi::Input     — unimidi-backed input endpoint
#   FolkRules::Midi::Output    — unimidi-backed output endpoint
#   FolkRules::CLI             — Thor-based `fr` command
#   FolkRules::Doctor          — environment verifier
module FolkRules
  class Error < StandardError; end

  autoload :CLI, "folk_rules/cli"
  autoload :Doctor, "folk_rules/doctor"
  autoload :Clock, "folk_rules/clock"

  module Midi
    autoload :Input, "folk_rules/midi/input"
    autoload :Output, "folk_rules/midi/output"
  end
end
