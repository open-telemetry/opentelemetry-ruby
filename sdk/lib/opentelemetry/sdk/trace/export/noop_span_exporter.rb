# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # A noop exporter that demonstrates and documents the SpanExporter
        # duck type. SpanExporter allows different tracing services to export
        # recorded data for sampled spans in their own format.
        #
        # To export data an exporter MUST be registered to the {Tracer} using
        # a {SimpleSampledSpanProcessor} or a {BatchSampledSpanProcessor}.
        class NoopSpanExporter
          # Called to export sampled {Span}s.
          #
          # @param [Enumerable<Span>] spans the list of sampled {Span}s to be
          #   exported.
          # @return [Integer] the result of the export.
          def export(spans)
            SUCCESS
          end

          # Called when {Tracer#shutdown} is called, if this exporter is
          # registered to a {Tracer} object.
          def shutdown; end
        end
      end
    end
  end
end
