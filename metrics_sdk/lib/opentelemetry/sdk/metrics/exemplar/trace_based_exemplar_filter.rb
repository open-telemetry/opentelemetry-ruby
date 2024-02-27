# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # TraceBasedExemplarFilter
        class TraceBasedExemplarFilter < ExemplarFilter
          def self.should_sample?(value, timestamp, attributes, context)
            ::OpenTelemetry::Trace.current_span(context).context.trace_flags.sampled?
          end
        end
      end
    end
  end
end
