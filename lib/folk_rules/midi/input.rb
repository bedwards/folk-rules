require "unimidi"

module FolkRules
  module Midi
    # Thin wrapper around a UniMIDI input endpoint. Runs a reader thread that
    # polls the endpoint and yields each message to registered callbacks.
    #
    # Endpoint selection uses CoreMidiNames for accurate per-port matching
    # (IAC buses all show as "Apple Inc. IAC Driver" in unimidi).
    class Input
      attr_reader :name

      def initialize(match:, poll_interval: 0.0005)
        @match = match
        @poll_interval = poll_interval
        @callbacks = []
        @thread = nil
        @stop = false
        @endpoint = nil
      end

      def open
        @endpoint = find_endpoint!
        @name = @display_name || endpoint_name(@endpoint)
        @endpoint.open
        self
      end

      def on_message(&blk)
        @callbacks << blk
        self
      end

      def start
        raise "not opened" unless @endpoint
        @stop = false
        @thread = Thread.new do
          Thread.current.name = "folk-rules midi input #{@name}"
          Thread.current.priority = 2
          loop do
            break if @stop
            msgs = @endpoint.gets
            msgs.each do |m|
              bytes = m[:data] || []
              next if bytes.empty?
              @callbacks.each { |cb| cb.call(*bytes) }
            end
            sleep @poll_interval
          end
        end
        self
      end

      def stop
        @stop = true
        @thread&.join(2)
        @endpoint&.close
        self
      end

      private

      def find_endpoint!
        # First try CoreMidiNames for accurate per-port matching
        require_relative "core_midi_names"
        info = CoreMidiNames.find_source(@match)
        if info
          @display_name = info[:display_name]
          return UniMIDI::Input.all[info[:index]]
        end

        # Fallback to unimidi name matching
        normalized = normalize(@match)
        candidates = UniMIDI::Input.all
        hit = candidates.find { |e| normalize(endpoint_name(e)).include?(normalized) }
        raise "no MIDI input matching #{@match.inspect}" unless hit
        hit
      end

      def endpoint_name(ep) = ep.respond_to?(:name) ? ep.name : ep.to_s

      def normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")
    end
  end
end
