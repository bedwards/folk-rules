require_relative "folk_rules/version"

# folk-rules — a pure-Ruby realtime MIDI framework for macOS.
#
# The public surface is intentionally tiny at v0.0.1; the full DSL lands in M2.
# See CLAUDE.md and memory/project_folk_rules*.md for locked architecture (D1-D7).
module FolkRules
  class Error < StandardError; end

  autoload :CLI, "folk_rules/cli"
  autoload :Doctor, "folk_rules/doctor"
end
