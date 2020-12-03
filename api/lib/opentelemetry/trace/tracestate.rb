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

        # TODO: should we add a DEFAULT Tracestate and an empty? method?
        # This would ensure we always have a valid non-nil Tracestate.
        # Propagators would then check for .empty? rather than .nil?

        # Returns a newly created {Tracestate} parsed from the header provided.
        #
        # @param [String] header Encoding of the tracestate header defined by
        #   the W3C Trace Context specification https://www.w3.org/TR/trace-context/
        # @return [Tracestate]
        def parse(header) # rubocop:disable Metrics/CyclomaticComplexity:
          return if header.nil? || header.empty?

          hash = header.split(',').each_with_object({}) do |member, memo|
            member.strip!
            kv = member.split('=')
            k, v = *kv
            next unless kv.length == 2 && valid_key?(k) && valid_value?(v)

            memo[k] = v
          end
          new(hash) unless hash.empty?
        end

        def from_hash(hash)
          new(hash)
        end

        private

        def valid_key?(_)
          true # TODO
        end

        def valid_value?(_)
          true # TODO
        end
      end

      def initialize(hash)
        @hash = hash.freeze
        # TODO: remove entries after the first 32
      end

      def [](key)
        h[key]
      end

      def []=(key, value)
        h = Hash[@hash]
        h[key] = value
        new(h)
      end

      def delete(key)
        return self unless @hash.key?(key)

        h = Hash[@hash]
        h.delete(key)
        new(h)
      end

      def to_s
        @hash.inject(+'') do |memo, (k, v)|
          memo << k << '=' << v << ','
        end.chop! || ''
      end
    end
  end
end
