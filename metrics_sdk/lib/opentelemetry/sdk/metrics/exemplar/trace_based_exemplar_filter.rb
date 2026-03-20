# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # TraceBasedExemplarFilter is an ExemplarFilter which makes measurements recorded 
        # in the context of a sampled parent span eligible for being an Exemplar
        class TraceBasedExemplarFilter < ExemplarFilter
          def self.should_sample?(value, timestamp, attributes, context)
            ::OpenTelemetry::Trace.current_span(context).context.trace_flags.sampled?
          end
        end
      end
    end
  end
end
