# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # TraceState represents the OpenTelemetry::Trace::Tracestate values that
      # are part of the OpenTelemetry ecosystem, contained in a single entry
      # using the `ot` key. The format and handling requirements are specified
      # at https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/tracestate-handling.md
      class TraceState
        class << self
          private :new # rubocop:disable Style/AccessModifierDeclarations

          # Returns a newly created TraceState parsed from the Tracestate provided.
          #
          # @param [OpenTelemetry::Trace::Tracestate] tracestate
          # @return [TraceState] A new TraceState instance or DEFAULT
          def from_tracestate(tracestate) # rubocop:disable Metrics/CyclomaticComplexity:
            return DEFAULT if tracestate.empty?

            ot = tracestate.value('ot')
            return DEFAULT if ot.nil? || ot.length > MAX_LIST_LENGTH

            hash = ot.split(';').each_with_object({}) do |member, memo|
              member.strip!
              kv = member.split(':')
              k, v = *kv
              # TODO: "the used keys MUST be unique." - do we validate the header during parsing or just during formatting?
              next unless kv.length == 2 && VALID_KEYS.include?(k) && VALID_VALUE.match?(v)

              memo[k] = v
            end
            return DEFAULT if hash.empty?

            new(hash)
          end

          # Returns a TraceState created from a Hash.
          #
          # @param [Hash<String, String>] hash Key-value pairs to store in the
          #   TraceState. Keys and values are validated against
          #   https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/tracestate-handling.md,
          #   and any invalid members are logged at DEBUG level and dropped.
          #   If the combined length exceeds 256 characters, the hash is
          #   logged at DEBUG level and DEFAULT is returned.
          # @return [TraceState] A new TraceState instance or DEFAULT
          def from_hash(hash)
            hash = hash.select do |k, v|
              valid = VALID_KEYS.include?(k) && VALID_VALUE.match?(v)
              OpenTelemetry.logger.debug("Invalid TraceState member - #{k} : #{v}") unless valid
              valid
            end
            if hash.sum { |k, v| k.length + v.length + 1 } + hash.count - 1 > MAX_LIST_LENGTH
              OpenTelemetry.logger.debug("Invalid TraceState, list too long - #{hash}")
              return DEFAULT
            end
            new(hash)
          end

          # @api private
          # Returns a new TraceState created from the Hash provided. This
          # skips validation of the keys and values, assuming they are already
          # valid.
          # This method is intended only for the use of instance methods in
          # this class.
          def create(hash)
            new(hash)
          end
        end

        MAX_LIST_LENGTH = 256 # Defined by https://www.w3.org/TR/trace-context/
        VALID_KEYS = %w[p r].freeze
        VALID_VALUE = /^[A-Za-z0-9_\-.]$/.freeze
        private_constant(:MAX_MEMBER_COUNT, :VALID_KEYS, :VALID_VALUE)

        # @api private
        # The constructor is private and only for use internally by the class.
        # Users should use the {from_hash} or {from_tracestate} factory methods to
        # obtain a {TraceState} instance.
        #
        # @param [Hash<String, String>] hash Key-value pairs
        # @return [TraceState]
        def initialize(hash)
          @hash = hash.freeze
        end

        # Returns the value associated with the given key, or nil if the key
        # is not present.
        #
        # @param [String] key The key to lookup.
        # @return [String] The value associated with the key, or nil.
        def value(key)
          @hash[key]
        end

        alias [] value

        # Adds a new key/value pair or updates an existing value for a given key.
        # Keys and values are validated against
        # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/tracestate-handling.md,
        # and any invalid members are logged at DEBUG level and
        # ignored. If adding the key/value pair would make the entire `ot` entry
        # exceed the 256 character limit, the pair will be logged at DEBUG
        # level and ignored.
        #
        # @param [String] key The key to add or update.
        # @param [String] value The value to add or update.
        # @return [TraceState] self, if unchanged, or a new TraceState containing
        #   the new or updated key/value pair.
        def set_value(key, value)
          unless VALID_KEYS.include?(key) && VALID_VALUE.match?(value)
            OpenTelemetry.logger.debug("Invalid Tracestate member - #{key} : #{value}")
            return self
          end

          # TODO: length limit
  
          h = Hash[@hash]
          h[key] = value
          self.class.create(h)
        end

        # Deletes the key/value pair associated with the given key.
        #
        # @param [String] key The key to remove.
        # @return [TraceState] self, if unchanged, or a new TraceState without
        #   the specified key.
        def delete(key)
          return self unless @hash.key?(key)

          h = Hash[@hash]
          h.delete(key)
          self.class.create(h)
        end

        # Sets the value of the `ot` key in tracestate to this TraceState
        # encoded as a string.
        #
        # @param [Tracestate] tracestate The Tracestate to update.
        # @return [Tracestate] tracestate, if unchanged, or a new Tracestate
        #   containing this TraceState under the `ot` key, encoded as a string.
        def this_is_a_deliberately_terrible_name_please_bikeshed(tracestate)
          tracestate.set_value('ot', to_s)
        end

        # Returns this TraceState encoded according to the specification at
        # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/tracestate-handling.md,
        #
        # @return [String] this TraceState encoded as a string.
        def to_s
          @hash.inject(+'') do |memo, (k, v)|
            memo << k << ':' << v << ';'
          end.chop! || ''
        end

        # Returns this TraceState as a Hash.
        #
        # @return [Hash] the members of this TraceState
        def to_h
          @hash.dup
        end

        # Returns true if this TraceState is empty.
        #
        # @return [Boolean] true if this TraceState is empty, else false.
        def empty?
          @hash.empty?
        end

        # Returns true if this TraceState equals other.
        #
        # @param [TraceState] other The TraceState for comparison.
        # @return [Boolean] true if this TraceState == other, else false.
        def ==(other)
          @hash == other.to_h
        end

        DEFAULT = new({})
      end
    end
  end
end
