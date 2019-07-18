# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A class that represents a trace identifier.
    #
    # @see https://www.w3.org/TR/trace-context/#trace-id
    class TraceId
      INVALID_ID = 0
      private_constant :INVALID_ID

      MAX_128BIT_UNSIGNED_INT = (1 << 128) - 1
      private_constant :MAX_128BIT_UNSIGNED_INT

      # Generates a random non-invalid TraceId
      #
      # @return [SpanId]
      def self.generate
        new(rand(1..MAX_128BIT_UNSIGNED_INT))
      end

      def initialize(id)
        @id = id
      end

      INVALID = new(INVALID_ID)

      # Checks if TraceId is valid
      #
      # @see https://www.w3.org/TR/trace-context/#trace-id
      #
      # @return [Boolean] true if valid
      def valid?
        @id != INVALID_ID
      end

      def ==(other)
        @id == other.id
      end

      # Returns the lowercase base16 encoding of this {TraceId}.
      #
      # @return [String]
      def to_lower_base16
        @to_lower_base16 ||= @id.to_s(16).rjust(32, '0').freeze
      end

      protected

      # The internal representation of this {TraceId}
      attr_reader :id
    end
  end
end
