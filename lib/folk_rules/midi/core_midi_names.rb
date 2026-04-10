require "ffi"

module FolkRules
  module Midi
    # Direct FFI bindings to CoreMIDI for reading per-port endpoint names.
    # The ffi-coremidi gem returns entity names, not port names, so IAC buses
    # all show as "Apple Inc. IAC Driver". This module reads the real names.
    module CoreMidiNames
      extend FFI::Library

      ffi_lib "/System/Library/Frameworks/CoreMIDI.framework/CoreMIDI"

      attach_function :num_sources, :MIDIGetNumberOfSources, [], :uint32
      attach_function :get_source, :MIDIGetSource, [:uint32], :uint32
      attach_function :num_destinations, :MIDIGetNumberOfDestinations, [], :uint32
      attach_function :get_destination, :MIDIGetDestination, [:uint32], :uint32
      attach_function :get_string_prop, :MIDIObjectGetStringProperty, [:uint32, :pointer, :pointer], :int32
      attach_function :cf_create_string, :CFStringCreateWithCString, [:pointer, :string, :uint32], :pointer
      attach_function :cf_get_cstring, :CFStringGetCString, [:pointer, :pointer, :long, :uint32], :bool
      attach_function :cf_string_length, :CFStringGetLength, [:pointer], :long
      attach_function :cf_release, :CFRelease, [:pointer], :void

      UTF8 = 0x08000100

      def self.endpoint_property(ref, prop)
        key = cf_create_string(nil, prop, UTF8)
        ptr = FFI::MemoryPointer.new(:pointer)
        status = get_string_prop(ref, key, ptr)
        cf_release(key)
        return nil unless status == 0
        cf = ptr.read_pointer
        return nil if cf.null?
        len = cf_string_length(cf)
        buf = FFI::MemoryPointer.new(:char, len * 4 + 1)
        cf_get_cstring(cf, buf, buf.size, UTF8)
        buf.read_string
      end

      def self.sources
        num_sources.times.map do |i|
          ref = get_source(i)
          {index: i, ref: ref,
           name: endpoint_property(ref, "name") || "",
           display_name: endpoint_property(ref, "displayName") || ""}
        end
      end

      def self.destinations
        num_destinations.times.map do |i|
          ref = get_destination(i)
          {index: i, ref: ref,
           name: endpoint_property(ref, "name") || "",
           display_name: endpoint_property(ref, "displayName") || ""}
        end
      end

      def self.find_source(match)
        m = normalize(match)
        sources.find { |s| normalize(s[:name]).include?(m) || normalize(s[:display_name]).include?(m) }
      end

      def self.find_destination(match)
        m = normalize(match)
        destinations.find { |d| normalize(d[:name]).include?(m) || normalize(d[:display_name]).include?(m) }
      end

      def self.normalize(s) = s.to_s.downcase.gsub(/[^a-z0-9]+/, "_")
    end
  end
end
