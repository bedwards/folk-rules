require "thor"
require_relative "doctor"

module FolkRules
  # Top-level `fr` command. Subcommands are added incrementally as milestones land.
  class CLI < Thor
    def self.exit_on_failure? = true

    desc "version", "Print the folk-rules version"
    def version
      puts FolkRules::VERSION
    end

    desc "doctor", "Verify the dev environment (ruby, Sonic Pi, IAC buses, MIDI gems)"
    method_option :verbose, type: :boolean, default: false, aliases: "-v"
    def doctor
      ok = Doctor.new(verbose: options[:verbose]).run
      exit(ok ? 0 : 1)
    end
  end
end
