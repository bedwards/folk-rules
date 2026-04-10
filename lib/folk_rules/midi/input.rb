require "unimidi"

module FolkRules
  module Midi
    # Thin wrapper around a UniMIDI input endpoint. Runs a reader thread that
    # polls the endpoint and yields each message to registered callbacks.
    #
    # Endpoint selection is by substring match against the endpoint name
    # (case-insensitive, non-alphanumerics collapsed). This matches how
    # macOS labels IAC ports ("IAC Driver folk_clock").
    class Input
      attr_reader :name

      # @param match [String] substring of the endpoint name to open
      # @param poll_interval [Float] seconds between gets when idle
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
        @name = endpoint_name(@endpoint)
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
        @thread&.join
        @endpoint&.close
        self
      end

      private

      def find_endpoint!
        normalized = normalize(@match)
        candidates = UniMIDI::Input.all
        hit = candidates.find { |e| normalize(endpoint_name(e)).include?(normalized) }
        raise "no MIDI input matching #{@match.inspect} (have: #{candidates.map { |c| endpoint_name(c) }.join(", ")})" unless hit
        hit
      end

      def endpoint_name(ep) = ep.respond_to?(:name) ? ep.name : ep.to_s

      def normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")
    end
  end
end
