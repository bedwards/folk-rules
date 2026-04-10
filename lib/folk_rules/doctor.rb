module FolkRules
  # Environment verifier invoked by `fr doctor`.
  #
  # Each check returns [ok, message]. The runner prints a colorized summary and
  # exits non-zero on any failure. Checks are deliberately cheap and idempotent.
  class Doctor
    REQUIRED_BUSES = %w[folk_clock folk_drums folk_pitched].freeze
    SONIC_PI_APP = "/Applications/Sonic Pi.app".freeze
    MIN_RUBY = Gem::Version.new("3.2.0")

    def initialize(verbose: false)
      @verbose = verbose
      @results = []
    end

    def run
      check("macOS", &method(:check_macos))
      check("ruby >= #{MIN_RUBY}", &method(:check_ruby))
      check("bundler", &method(:check_bundler))
      check("Sonic Pi app", &method(:check_sonic_pi))
      check("unimidi gem loadable", &method(:check_unimidi))
      check("ffi-coremidi gem loadable", &method(:check_ffi_coremidi))
      check("IAC Driver enabled", &method(:check_iac_enabled))
      REQUIRED_BUSES.each { |bus| check("IAC bus '#{bus}'") { check_bus(bus) } }
      print_summary
      @results.all? { |_, ok, _| ok }
    end

    private

    def check(name)
      ok, msg = yield
      @results << [name, ok, msg]
    rescue => e
      @results << [name, false, "exception: #{e.class}: #{e.message}"]
    end

    def check_macos
      ok = RUBY_PLATFORM.include?("darwin")
      [ok, ok ? RUBY_PLATFORM : "folk-rules targets macOS only"]
    end

    def check_ruby
      cur = Gem::Version.new(RUBY_VERSION)
      [cur >= MIN_RUBY, RUBY_VERSION]
    end

    def check_bundler
      require "bundler"
      [true, Bundler::VERSION]
    rescue LoadError
      [false, "bundler not installed"]
    end

    def check_sonic_pi
      ok = File.directory?(SONIC_PI_APP)
      [ok, ok ? SONIC_PI_APP : "not found at #{SONIC_PI_APP} (install from sonic-pi.net)"]
    end

    def check_unimidi
      require "unimidi"
      [true, UniMIDI::VERSION]
    rescue LoadError => e
      [false, "gem not loadable: #{e.message}"]
    end

    def check_ffi_coremidi
      require "coremidi"
      [true, defined?(CoreMIDI::VERSION) ? CoreMIDI::VERSION : "loaded"]
    rescue LoadError => e
      [false, "gem not loadable: #{e.message}"]
    end

    def check_iac_enabled
      require_relative "midi/core_midi_names"
      srcs = Midi::CoreMidiNames.sources
      dsts = Midi::CoreMidiNames.destinations
      has_any = srcs.any? || dsts.any?
      [has_any, has_any ? "CoreMIDI reachable (#{srcs.size} in / #{dsts.size} out)" : "no MIDI endpoints — enable IAC in Audio MIDI Setup"]
    rescue => e
      [false, "CoreMIDI probe failed: #{e.message}"]
    end

    def check_bus(name)
      require_relative "midi/core_midi_names"
      src = Midi::CoreMidiNames.find_source(name)
      dst = Midi::CoreMidiNames.find_destination(name)
      if src && dst
        [true, "in: #{src[:display_name]}, out: #{dst[:display_name]}"]
      elsif src || dst
        dir = src ? "in" : "out"
        found = src || dst
        [false, "only #{dir} visible (#{found[:display_name]}) — check Audio MIDI Setup"]
      else
        [false, "not found — create in Audio MIDI Setup → IAC Driver"]
      end
    rescue => e
      [false, "probe failed: #{e.message}"]
    end

    def normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")

    def print_summary
      width = @results.map { |n, _, _| n.length }.max
      @results.each do |name, ok, msg|
        mark = ok ? "\e[32m✓\e[0m" : "\e[31m✗\e[0m"
        puts "#{mark} #{name.ljust(width)}  #{msg}"
      end
      failed = @results.count { |_, ok, _| !ok }
      puts(failed.zero? ? "\n\e[32mAll checks passed.\e[0m" : "\n\e[31m#{failed} check(s) failed.\e[0m")
    end
  end
end
