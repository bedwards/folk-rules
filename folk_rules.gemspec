require_relative "lib/folk_rules/version"

Gem::Specification.new do |spec|
  spec.name = "folk_rules"
  spec.version = FolkRules::VERSION
  spec.authors = ["Brian Edwards"]
  spec.email = ["noreply@example.com"]

  spec.summary = "Production-grade Ruby framework for realtime MIDI composition on macOS."
  spec.description = "folk-rules is a pure-Ruby realtime MIDI framework that slaves to an external MIDI clock " \
    "(e.g. Bitwig) and drives drums, pitched instruments, and CC modulation via macOS IAC buses. " \
    "Songs are plain Ruby files with a world-class DSL, committed to git with clean diffs."
  spec.homepage = "https://github.com/bedwards/folk-rules"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.platform = "universal-darwin"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,exe}/**/*", "README.md", "CLAUDE.md", "LICENSE.txt"].reject { |f| File.directory?(f) }
  end
  spec.bindir = "exe"
  spec.executables = ["fr"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "unimidi", "~> 0.5"
  spec.add_dependency "ffi-coremidi", "~> 0.3"
  spec.add_dependency "tty-cursor", "~> 0.7"
  spec.add_dependency "tty-screen", "~> 0.8"
  spec.add_dependency "tty-box", "~> 0.7"
end
