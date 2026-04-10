# folk-rules

A production-grade, pure-Ruby realtime MIDI framework for composing music on macOS. Slaves to an external MIDI clock (Bitwig 6) and drives drums, pitched instruments, and CC modulation over IAC buses — with songs written as plain Ruby files that diff cleanly in git.

## Why

- **Plain text, git-native.** Songs are Ruby files you commit. No binary project blobs.
- **Ruby all the way down.** No Python bridges, no shell glue. The DSL feels native to a Ruby developer.
- **Tight with Bitwig.** Clock and transport come from Bitwig via IAC. Notes and CC go back.
- **Modular and balanced.** Drums, chords, arps, melodies, bass, humanize, fills, bends, CC — each at the same depth.
- **Verifiable without ears.** `fr-ruby verify` runs songs in simulation and asserts timing, notes, and CC.

## Stack

Bitwig 6 · Ruby 3.2+ · Thor · unimidi · ffi-coremidi · tty-cursor/screen/box · standard · minitest · rspec · git · GitHub · VS Code · Claude Code · macOS IAC Driver.

## Install

```sh
git clone git@github.com:bedwards/folk-rules.git
cd folk-rules
bundle install
bundle exec rake          # tests + standardrb
bundle exec exe/fr-ruby doctor # verify environment
```

Global CLI shim:

```sh
mkdir -p ~/.local/bin
cat > ~/.local/bin/fr-ruby <<'SH'
#!/usr/bin/env bash
exec bundle exec --gemfile="$HOME/vibe/folk-rules/Gemfile" fr "$@"
SH
chmod +x ~/.local/bin/fr
```

## Prerequisites

1. **Audio MIDI Setup → IAC Driver** enabled with three buses: `folk_clock`, `folk_drums`, `folk_pitched`.
2. **Bitwig 6** sending MIDI clock on `folk_clock`, receiving on `folk_drums` / `folk_pitched`.
3. **Ruby 3.2+** (Homebrew: `brew install ruby`).

`fr-ruby doctor` checks everything and tells you what's missing.

## CLI

```
fr-ruby doctor          # verify environment
fr-ruby version         # print version
fr-ruby verify <song>   # simulate + assert MIDI output
fr-ruby clock monitor   # live BPM/bar/beat from Bitwig
fr-ruby tui             # read-only terminal monitor
```

## Writing Songs

Single-file:

```ruby
require "folk_rules"

FolkRules.song "my_song" do
  context_set key: :g, scale: :major, beats_per_bar: 4,
    progression: [:g, :c, :d, :em]

  bus :drums, to: "folk_drums"
  bus :pitched, to: "folk_pitched"

  drums :kit, bus: :drums, channel: 9 do
    kick       "x...x...x...x..."
    snare      "....x.......x..."
    hat_closed "x.x.x.x.x.x.x.x."
  end

  bass :upright, bus: :pitched, channel: 0, octave: 2
  chord :guitar, bus: :pitched, channel: 1, voicing: :major
  arp :banjo, bus: :pitched, channel: 2, mode: :up
  melody :fiddle, bus: :pitched, channel: 3, scale: [:g, :blues]

  cc_lfo :filter, bus: :pitched, cc: 74, wave: :sine, rate: 0.5
end
```

Multi-file: `songs/examples/07_folk_country_jam/` shows a full production split across `song.rb` + `parts/*.rb`.

## Modules

Composable transforms chained on any part via `modules: [...]`:

| Module | What it does |
|---|---|
| `Arpeggiator` | Chord → one note at a time (up/down/updown/random) |
| `ChordExpand` | Root → voiced chord (triad/7th/sus/dim/aug) |
| `NoteRepeat` | Rolls/fills with velocity decay |
| `Humanize` | Velocity/timing/pitch jitter (seeded RNG) |
| `MultiNote` | Stack intervals (octave doubles, fifths) |
| `NoteLength` | Gate/staccato/legato duration |
| `NoteFilter` | Filter by pitch/velocity/channel range |
| `NoteLatch` | Sustain across beats |
| `Fill` | Bar-boundary fills (light/medium/heavy) |
| `PitchBend` | Probability-based pitch slides |

## Example Songs

| # | Name | Events/8bars | What it demonstrates |
|---|---|---|---|
| 01 | `kick` | 32 | Simplest possible song |
| 02 | `four_on_floor` | 112 | Kick/snare/hats |
| 03 | `progression` | 296 | Bb major + G minor pent melody (D9 override) |
| 04 | `arp_dreams` | 224 | Module chain: arp + note repeat |
| 05 | `humanize_demo` | 288 | Humanize + staccato + octave double |
| 06 | `expressive` | 434 | Fills + bends + CC LFOs |
| 07 | `folk_country_jam` | 898 | Multi-file production: 7 instruments, all modules |

## Architecture

See `CLAUDE.md` for locked decisions D1–D12. Key points:

- **In-process engine.** One Ruby process does clock reading, scheduling, and MIDI I/O via `ffi-coremidi`.
- **Clock reader.** `FolkRules::Clock` reads MIDI clock at 24 PPQN, smooths BPM over a rolling window.
- **Shared musical context.** Song-level key/scale/progression; per-module overrides via `dup_with`.
- **MIDI input.** `Input::ChordStream` reads live chords from Bitwig for real-time progression following.
- **TUI monitor.** `fr-ruby tui` shows live transport, BPM, chord, and MIDI event log.

## License

MIT.
