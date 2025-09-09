# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      # Span flags constants following the OTLP specification
      module SpanFlags
        # Indicates that the span context has isRemote information
        SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK = 256 # 0x100

        # Indicates that the span context is remote
        SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK = 512 # 0x200
      end
    end
  end
end
