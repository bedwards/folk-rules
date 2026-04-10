module FolkRules
  module Modules
    # ChordExpand: takes a single root note and expands it into a chord
    # using intervals derived from the current scale/context.
    #
    # Voicings: :triad, :seventh, :sus4, :sus2, :power, :octave, :drop2
    class ChordExpand < Base
      VOICINGS = {
        triad: [0, 2, 4],       # scale degrees (0-indexed)
        seventh: [0, 2, 4, 6],
        sus4: [0, 3, 4],        # root, 4th, 5th (scale degrees)
        sus2: [0, 1, 4],        # root, 2nd, 5th
        power: [0, 4],          # root, 5th
        octave: [0]             # just the root (+ octave double)
      }.freeze

      def initialize(voicing: :triad, octave_double: false)
        @voicing = voicing
        @octave_double = octave_double
      end

      def process(events, context, beat: 0, bar: 0)
        events.flat_map do |event|
          expand_note(event, context)
        end
      end

      private

      def expand_note(event, context)
        root = event.note
        root_pc = root % 12
        scale_pcs = FolkRules::Note::SCALES.fetch(context.scale, FolkRules::Note::SCALES[:major])

        # Find root's position in the scale
        root_in_scale = scale_pcs.index((root_pc - context.key_pc) % 12) || 0

        degrees = VOICINGS.fetch(@voicing, VOICINGS[:triad])
        notes = degrees.map do |deg|
          idx = (root_in_scale + deg) % scale_pcs.length
          octave_bump = (root_in_scale + deg) / scale_pcs.length
          root + scale_pcs[idx] - scale_pcs[root_in_scale] + (octave_bump * 12)
        end

        notes << (root + 12) if @octave_double

        notes.map do |n|
          FolkRules::Part::NoteEvent.new(
            note: n, velocity: event.velocity,
            duration: event.duration, channel: event.channel
          )
        end
      end
    end
  end
end
