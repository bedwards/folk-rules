require "unimidi"

module FolkRules
  module Midi
    # Thin wrapper around a UniMIDI output endpoint. Used by tests (to pump
    # clock bytes) and later by the scheduler (M2) to emit notes and CC.
    class Output
      attr_reader :name

      def initialize(match:)
        @match = match
        @endpoint = nil
      end

      def open
        @endpoint = find_endpoint!
        @name = endpoint_name(@endpoint)
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
        normalized = normalize(@match)
        candidates = UniMIDI::Output.all
        hit = candidates.find { |e| normalize(endpoint_name(e)).include?(normalized) }
        raise "no MIDI output matching #{@match.inspect} (have: #{candidates.map { |c| endpoint_name(c) }.join(", ")})" unless hit
        hit
      end

      def endpoint_name(ep) = ep.respond_to?(:name) ? ep.name : ep.to_s

      def normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")
    end
  end
end
