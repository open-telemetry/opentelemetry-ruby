# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Propagation
      # Formatter for serializing and deserializing a SpanContext into a binary format.
      class BinaryFormat
        EMPTY_BYTE_ARRAY = [].freeze

        private_constant(:EMPTY_BYTE_ARRAY)

        def to_bytes(span_context)
          EMPTY_BYTE_ARRAY
        end

        def from_bytes(bytes)
          Trace::SpanContext.invalid
        end
      end
    end
  end
end
