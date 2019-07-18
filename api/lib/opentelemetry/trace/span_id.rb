# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A class that represents a span identifier.
    #
    # @see https://www.w3.org/TR/trace-context/#parent-id
    class SpanId
      INVALID_ID = 0
      private_constant :INVALID_ID

      MAX_64BIT_UNSIGNED_INT = (1 << 64) - 1
      private_constant :MAX_64BIT_UNSIGNED_INT

      # Generates a random non-invalid SpanId
      #
      # @return [SpanId]
      def self.generate
        new(rand(1..MAX_64BIT_UNSIGNED_INT))
      end

      def initialize(id)
        @id = id
      end

      INVALID = new(INVALID_ID)

      # Checks if SpanId is valid
      #
      # @see https://www.w3.org/TR/trace-context/#parent-id
      #
      # @return [Boolean] true if valid
      def valid?
        @id != INVALID_ID
      end

      # Returns the lowercase base16 encoding of this {SpanId}.
      #
      # @return [String]
      def to_lower_base16
        @to_lower_base16 ||= @id.to_s(16).rjust(16, '0').freeze
      end

      def ==(other)
        @id == other.id
      end

      protected

      # The internal representation of this {SpanId}
      attr_reader :id
    end
  end
end
