# CLAUDE.md — folk-rules

Notes for LLM collaborators. Humans should read `README.md` first.

## Invariants (do not violate)

1. **macOS only.** No Linux/Windows code paths, no cross-platform CI.
2. **Stack purity.** Allowed: Bitwig 6, Sonic Pi, git, GitHub, Ruby + top-tier Ruby gems, our custom code, VS Code, Claude Code, macOS IAC Driver. **No Python, no Node, no shell glue where Ruby suffices.** If you reach for `sonic-pi-tool` (Python), stop — talk OSC directly with `osc-ruby`.
3. **Pure-Ruby in-process realtime engine.** folk-rules does its own MIDI I/O and scheduling via `ffi-coremidi` in one process. There is **no separate daemon**, no OSC bridge used for timing, and Sonic Pi is an *optional* output adapter — not a dependency for clock or scheduling.
4. **Two inspiration products are never named in this repo.** (See memory.) Features may match, product names must not appear in code, commits, PRs, issues, README, or CLAUDE.md.
5. **No race-ahead on one component.** Drum sequencer, chords, arp, melody, bass, humanize, fills, CC — keep depth balanced across milestones.
6. **No uncommitted files. No open PRs at tick end. No unreviewed Gemini feedback.**
7. **Bump minor + tag on every merge.** `vX.Y.Z`, push tags.

## Locked architecture (D1–D7, see memory for full rationale)

- **D1** Pure-Ruby in-process engine. `FolkRules::Clock` reads MIDI clock (0xF8/FA/FB/FC/F2) from IAC `folk_clock` in a high-priority thread, smooths BPM over a rolling window, exposes `on_tick`/`on_beat`/`on_bar`/`on_start`/`on_stop` callbacks. Scheduler emits notes/CC directly to IAC `folk_drums` and `folk_pitched` via `ffi-coremidi`.
- **D2** Three IAC buses: `folk_clock` (in only, from Bitwig), `folk_drums` (notes + CC out), `folk_pitched` (notes + CC out).
- **D3** Repo layout: `lib/folk_rules/` core, `exe/fr` CLI, `songs/<name>/` for songs (single-file `songs/hello.rb` also valid), `test/` minitest for pure logic, `spec/` rspec for MIDI loopback integration.
- **D4** Ruby DSL for songs — must feel native and cozy to a Ruby dev.
- **D5** CLI: `fr-ruby <doctor|run|verify|midi|clock|new> ... -- <wrapped>`. Thor. `--help` at every level.
- **D6** Verification is no-human: minitest on pure logic; rspec loopback records output MIDI with `ffi-coremidi` and asserts on timing/notes/CC; `fr-ruby verify` runs the same harness on a song.
- **D7** Workflow: worktree per branch, PR, wait Gemini, triage by severity, file issues for medium+, merge, bump minor, tag, delete worktree.

## Memory pointers

Durable research and decisions live at `~/.claude/projects/-Users-bedwards-vibe-folk-rules/memory/`:

- `project_folk_rules.md` — what, why, build order, stack, discipline.
- `project_folk_rules_research.md` — verified facts about Sonic Pi clock behavior, Bitwig drum mapping, Ruby MIDI gems, stack purity rule.

Re-read these at the start of any session before editing code. Do not re-derive the architecture.

## Quick commands

```sh
bundle exec rake                     # test + spec + standardrb
bundle exec rake test                # minitest only (pure logic)
bundle exec rake spec                # rspec only (integration; iac-tagged skipped by default)
FOLK_RULES_IAC=1 bundle exec rake spec  # run IAC-gated integration (requires folk_clock bus free)
bundle exec exe/fr-ruby doctor -v         # environment check
bundle exec exe/fr-ruby clock monitor     # live BPM/bar/beat from Bitwig
bundle exec exe/fr-ruby verify songs/examples/01_kick.rb  # simulated verify
bundle exec exe/fr-ruby version
```

## Clock architecture (M1)

`FolkRules::Clock` is pure Ruby, zero MIDI coupling — it takes a `now:` time
source for deterministic tests and a generic `attach(input)` call where the
input is anything that responds to `on_message(&block)` yielding MIDI bytes.

Smoother: sliding window over the last N ticks (default 96 = 4 beats at 24
PPQN). BPM is computed as `60.0 / (mean_interval * PPQN)`. Unit tests drive
the clock with a fake monotonic time source and assert sub-0.01 BPM accuracy
against stable sources and successful convergence after tempo changes.

The rspec `:iac` loopback test pumps `0xF8` bytes from a `Midi::Output` into
the real `folk_clock` IAC bus while a `Midi::Input` on the same bus feeds a
live `Clock`. Asserts BPM within 0.5 of the target. Gated on `FOLK_RULES_IAC=1`
because CI runners have no IAC driver.

## Song DSL + Drum Sequencer (M2)

`FolkRules.song` is the top-level DSL. A song declares context (key/scale/
progression/rhythm), buses, and parts. Drum parts use pattern strings
(`"x...x..."`) where each character is one subdivision step:
- `x` = hit (velocity 100), `X` = accent (127), `o` = ghost (50), `.`/`-` = rest

The `Scheduler` subscribes to `Clock` tick callbacks, divides ticks into
subdivision steps, and emits MIDI note-on events to the configured outputs.
In simulated mode (used by `fr-ruby verify`), it pumps a fake clock and captures
all events into a `MemoryOutput` for assertion.

`MusicalContext` (D9) holds the song's key, scale, progression, and rhythm.
Each module reads from context but may override locally — a chord part in
Bb major and a melody in G minor pentatonic coexist via `dup_with`.

Example songs under `songs/examples/` are the real regression suite (D10).
`fr-ruby verify` runs each song through the simulator and checks for valid MIDI.
Failing examples block merge.

## Composable Modules (M3a+M3b, D12)

All modules implement `process(events, context, beat:, bar:) -> [NoteEvent]`.
Chain via `modules: [mod1, mod2]` on any pitched part. Order matters.

Available: Arpeggiator, ChordExpand, NoteRepeat, Humanize, MultiNote,
NoteLength, NoteFilter, NoteLatch, Fill, PitchBend.

## Expressive Layer (M5)

- `Modules::Fill` — bar-boundary fills with density + decay
- `Modules::PitchBend` — probability-based pitch slides
- `CcLfo` — song-level CC modulation: sine/triangle/saw/square/random
- Scheduler emits `CcEvent` alongside `MidiEvent`; MemoryOutput#cc_messages

## MIDI Input (M2b, D8)

`Input::ChordStream` reads note-on/off from a bus and identifies held chords.
Thread-safe, `on_chord_change` callback, rolling history. Can be bound as a
progression source for MusicalContext.

## TUI Monitor (M-tui, D11)

`fr-ruby tui` shows live transport, BPM, bar/beat, key/chord, and a scrolling
MIDI event log. Built on tty-cursor/screen/box. Read-only, 10fps, q to quit.

## Example Songs (D10)

Songs 01–07 under `songs/examples/` are the regression suite. CI verifies all
of them. Song 07 is a multi-file folk/country production exercising every
feature: 7 instruments, all modules, CC LFOs, D9 scale override.

## Gotchas

- `unimidi` and `ffi-coremidi` last released 2022; pin versions. Prefer forking over swapping.
- Bitwig Drum Machine pads start at C1 = MIDI 36. Sonic Pi `:c1` = MIDI 24. Default octave shift +12.
- Sonic Pi cannot natively sync to external MIDI clock. That is why we own the clock reader in Ruby.
- Chord symbols like `:am`, `:fsharp7` are parsed by `Note.chord_root` which strips quality suffixes.
