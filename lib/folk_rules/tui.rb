require "tty-cursor"
require "tty-screen"
require "tty-box"

module FolkRules
  # Read-only terminal UI for monitoring a running folk-rules session.
  # Shows clock state, current chord, bar/beat, active modules, recent
  # MIDI events, and BPM. Renders at ~10fps, resilient to terminal resize.
  #
  # Pure Ruby, no interaction beyond 'q' to quit.
  class Tui
    REFRESH_HZ = 10

    def initialize
      @cursor = TTY::Cursor
      @running = false
      @state = default_state
      @event_log = []
      @max_log = 20
    end

    # Update state from external sources (clock, scheduler, etc.)
    def update(
      bpm: nil, bar: nil, beat: nil, running: nil,
      chord: nil, key: nil, scale: nil,
      event: nil, cc_event: nil
    )
      @state[:bpm] = bpm if bpm
      @state[:bar] = bar if bar
      @state[:beat] = beat if beat
      @state[:transport] = running ? "PLAYING" : "STOPPED" unless running.nil?
      @state[:chord] = format_chord(chord) if chord
      @state[:key] = key if key
      @state[:scale] = scale if scale
      log_event(event) if event
      log_event(cc_event, cc: true) if cc_event
    end

    # Render a single frame to a string (for testing).
    def render_frame
      w = screen_width
      lines = []
      lines << header_line(w)
      lines << clock_line(w)
      lines << chord_line(w)
      lines << separator(w)
      lines << "  Recent MIDI Events:"
      @event_log.last(visible_log_lines).each { |e| lines << "    #{e}" }
      lines << ""
      lines << footer_line(w)
      lines.join("\n")
    end

    # Run the TUI loop (blocking). Call from `fr tui`.
    def run
      @running = true
      print @cursor.hide
      print @cursor.clear_screen
      setup_quit_handler

      while @running
        print @cursor.move_to(0, 0)
        print render_frame
        print @cursor.clear_screen_down
        sleep(1.0 / REFRESH_HZ)
      end
    ensure
      print @cursor.show
      print @cursor.clear_screen
    end

    def stop
      @running = false
    end

    private

    def default_state
      {
        bpm: nil, bar: 0, beat: 0,
        transport: "STOPPED",
        chord: "—", key: :c, scale: :major
      }
    end

    def screen_width
      TTY::Screen.width
    rescue
      80
    end

    def visible_log_lines
      [begin
        TTY::Screen.height
      rescue
        24
      end - 10, 5].max
    end

    def header_line(w)
      title = " folk-rules TUI v#{FolkRules::VERSION} "
      pad = "═" * [(w - title.length) / 2, 0].max
      "\e[1;36m#{pad}#{title}#{pad}\e[0m"
    end

    def clock_line(_w)
      bpm_str = @state[:bpm] ? format("%.1f", @state[:bpm]) : "—"
      transport_color = (@state[:transport] == "PLAYING") ? "\e[32m" : "\e[31m"
      "  #{transport_color}#{@state[:transport]}\e[0m  " \
        "BPM: \e[1m#{bpm_str}\e[0m  " \
        "Bar: \e[1m#{@state[:bar]}\e[0m  " \
        "Beat: \e[1m#{@state[:beat]}\e[0m"
    end

    def chord_line(_w)
      "  Key: \e[1m#{@state[:key]} #{@state[:scale]}\e[0m  " \
        "Chord: \e[1;33m#{@state[:chord]}\e[0m"
    end

    def separator(w)
      "─" * w
    end

    def footer_line(_w)
      "\e[2m  Press q to quit\e[0m"
    end

    def format_chord(chord)
      return "—" unless chord
      if chord.is_a?(Hash)
        "#{chord[:root]}#{chord[:quality]}"
      else
        chord.to_s
      end
    end

    def log_event(event, cc: false)
      ts = Time.now.strftime("%H:%M:%S.%L")
      @event_log << if cc
        "[#{ts}] CC ch=#{event.channel} cc=#{event.cc} val=#{event.value} bus=#{event.bus}"
      else
        "[#{ts}] NOTE ch=#{event.channel} n=#{event.note} v=#{event.velocity} bus=#{event.bus}"
      end
      @event_log.shift while @event_log.size > @max_log
    end

    def setup_quit_handler
      Thread.new do
        loop do
          ch = begin
            $stdin.getc
          rescue
            nil
          end
          if ch == "q" || ch == "Q"
            @running = false
            break
          end
        end
      end
    end
  end
end
