require "unimidi"

module FolkRules
  module Midi
    # Thin wrapper around a UniMIDI output endpoint.
    # Uses CoreMidiNames for accurate per-port matching on IAC buses.
    class Output
      attr_reader :name

      def initialize(match:)
        @match = match
        @endpoint = nil
      end

      def open
        @endpoint = find_endpoint!
        @name = @display_name || endpoint_name(@endpoint)
        @endpoint.open
        self
      end

      def puts(*bytes)
        @endpoint.puts(*bytes)
      end

      def close
        @endpoint&.close
        self
      end

      private

      def find_endpoint!
        require_relative "core_midi_names"
        info = CoreMidiNames.find_destination(@match)
        if info
          @display_name = info[:display_name]
          return UniMIDI::Output.all[info[:index]]
        end

        normalized = normalize(@match)
        candidates = UniMIDI::Output.all
        hit = candidates.find { |e| normalize(endpoint_name(e)).include?(normalized) }
        raise "no MIDI output matching #{@match.inspect}" unless hit
        hit
      end

      def endpoint_name(ep) = ep.respond_to?(:name) ? ep.name : ep.to_s

      def normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")
    end
  end
end
