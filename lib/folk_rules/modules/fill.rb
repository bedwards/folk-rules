module FolkRules
  module Modules
    # Fill: triggers drum fills on configurable bar boundaries.
    # When a fill bar is reached, replaces the normal pattern with a fill
    # pattern (rapid notes with velocity contour).
    #
    # Typically used on drum parts but works on any part.
    class Fill < Base
      def initialize(every: 4, density: :medium, decay: 0.9, seed: nil)
        @every = every # trigger every N bars
        @density = density # :light, :medium, :heavy
        @decay = decay
        @rng = seed ? Random.new(seed) : Random.new
      end

      def process(events, _context, beat: 0, bar: 0)
        return events unless fill_bar?(bar)

        # On fill bars, add extra hits
        fill_events = events.flat_map { |e| generate_fill(e) }
        events + fill_events
      end

      private

      def fill_bar?(bar)
        bar > 0 && (bar % @every) == 0
      end

      def generate_fill(event)
        count = case @density
        when :light then 2
        when :medium then 3
        when :heavy then 5
        else 3
        end

        vel = event.velocity.to_f
        count.times.map do
          v = (vel * (0.7 + @rng.rand * 0.3)).round.clamp(1, 127)
          vel *= @decay
          FolkRules::Part::NoteEvent.new(
            note: event.note + @rng.rand(-2..2),
            velocity: v,
            duration: event.duration * 0.25,
            channel: event.channel
          )
        end
      end
    end
  end
end
