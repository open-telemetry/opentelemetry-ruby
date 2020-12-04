# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Tracestate is a part of SpanContext, represented by an immutable list of
    # string key/value pairs and formally defined by the W3C Trace Context
    # specification https://www.w3.org/TR/trace-context/
    class Tracestate
      class << self
        private :new # rubocop:disable Style/AccessModifierDeclarations

        # Returns a newly created Tracestate parsed from the header provided.
        #
        # @param [String] header Encoding of the tracestate header defined by
        #   the W3C Trace Context specification https://www.w3.org/TR/trace-context/
        # @return [Tracestate] A new Tracestate instance or DEFAULT
        def from_string(header) # rubocop:disable Metrics/CyclomaticComplexity:
          return DEFAULT if header.nil? || header.empty?

          hash = header.split(',').each_with_object({}) do |member, memo|
            member.strip!
            kv = member.split('=')
            k, v = *kv
            next unless kv.length == 2 && valid_key?(k) && valid_value?(v)

            memo[k] = v
          end
          return DEFAULT if hash.empty?

          new(hash)
        end

        # Returns a Tracestate created from a Hash.
        #
        # @param [Hash<String, String>] hash Key-value pairs to store in the
        #   Tracestate. Keys and values are validated against the W3C Trace
        #   Context specification, and any invalid members are logged at
        #   DEBUG level and dropped.
        # @return [Tracestate] A new Tracestate instance or DEFAULT
        def from_hash(hash)
          hash = hash.select do |k, v|
            valid = valid_key?(k) && valid_value?(v)
            OpenTelemetry.logger.debug("Invalid Tracestate member - #{k} : #{v}") unless valid
            valid
          end
          new(hash)
        end

        private

        def valid_key?(key)
          %r(^[a-z][a-z0-9_\-*/]{,255}$).match?(key) || %r(^[a-z0-9][a-z0-9_\-*/]{,240}@[a-z][a-z0-9_\-*/]{,13}$).match?(key)
        end

        def valid_value?(value)
          /^[ -~&&[^,=]]{,255}[!-~&&[^,=]]$/.match?(value)
        end
      end

      MAX_MEMBER_COUNT = 32 # Defined by https://www.w3.org/TR/trace-context/

      def initialize(hash)
        excess = MAX_MEMBER_COUNT - hash.size
        hash = Hash[hash.drop(excess)] if excess.positive?
        @hash = hash.freeze
      end

      # Returns the value associated with the given key, or nil if the key
      # is not present.
      #
      # @param [String] key The key to lookup.
      # @return [String] The value associated with the key, or nil.
      def value(key)
        h[key]
      end

      # Adds a new key/value pair or updates an existing value for a given key.
      # Keys and values are validated against the W3C Trace Context
      # specification, and any invalid members are logged at DEBUG level and
      # ignored.
      #
      # @param [String] key The key to add or update.
      # @param [String] value The value to add or update.
      # @return [Tracestate] self, if unchanged, or a new Tracestate containing
      #   the new or updated key/value pair.
      def set_value(key, value)
        return self unless valid_key?(key) && valid_value?(value)

        h = Hash[@hash]
        h[key] = value
        new(h)
      end

      # Deletes the key/value pair associated with the given key.
      #
      # @param [String] key The key to remove.
      # @return [Tracestate] self, if unchanged, or a new Tracestate without
      #   the specified key.
      def delete(key)
        return self unless @hash.key?(key)

        h = Hash[@hash]
        h.delete(key)
        new(h)
      end

      # Returns this Tracestate encoded according to the W3C Trace Context
      # specification https://www.w3.org/TR/trace-context/
      #
      # @return [String] this Tracestate encoded as a string.
      def to_s
        @hash.inject(+'') do |memo, (k, v)|
          memo << k << '=' << v << ','
        end.chop! || ''
      end

      # Returns true if this Tracestate is empty.
      #
      # @return [Boolean] true if this Tracestate is empty, else false.
      def empty?
        @hash.empty?
      end

      DEFAULT = new({})
    end
  end
end
