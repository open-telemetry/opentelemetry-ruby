# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module Opentelemetry
  module Proto
    module Trace
      module V1
        # SpanFlags represents constants used to interpret the
        # Span.flags field, which is protobuf 'fixed32' type and is to
        # be used as bit-fields. Each non-zero value defined in this enum is
        # a bit-mask.  To extract the bit-field, for example, use an
        # expression like:
        #   (span.flags & SPAN_FLAGS_TRACE_FLAGS_MASK)
        # See https://www.w3.org/TR/trace-context-2/#trace-flags for the flag definitions.
        # Note that Span flags were introduced in version 1.1 of the
        # OpenTelemetry protocol.  Older Span producers do not set this
        # field, consequently consumers should not rely on the absence of a
        # particular flag bit to indicate the presence of a particular feature.
        module SpanFlags
          # The zero value for the enum. Should not be used for comparisons.
          # Instead use bitwise "and" with the appropriate mask as shown above.
          SPAN_FLAGS_DO_NOT_USE = 0

          # Bits 0-7 are used for trace flags.
          SPAN_FLAGS_TRACE_FLAGS_MASK = 255

          # Bits 8 and 9 are used to indicate that the parent span or link span is remote.
          # Bit 8 (`HAS_IS_REMOTE`) indicates whether the value is known.
          # Bit 9 (`IS_REMOTE`) indicates whether the span or link is remote.
          SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK = 256

          # Bit 9 (`IS_REMOTE`) indicates whether the span or link is remote.
          SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK = 512
        end
      end
    end
  end
end
