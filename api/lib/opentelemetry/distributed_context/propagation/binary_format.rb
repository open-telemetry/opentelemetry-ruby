# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    module Propagation
      # Formatter for serializing and deserializing a SpanContext into a binary format.
      class BinaryFormat
        EMPTY_BYTE_ARRAY = [].freeze

        private_constant(:EMPTY_BYTE_ARRAY)

        def to_bytes(span_context)
          raise ArgumentError if span_context.nil?

          EMPTY_BYTE_ARRAY
        end

        def from_bytes(bytes)
          raise ArgumentError if bytes.nil?

          OpenTelemetry::Trace::SpanContext.invalid
        end
      end
    end
  end
end
