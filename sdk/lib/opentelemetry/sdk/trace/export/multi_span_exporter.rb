# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # Implementation of the SpanExporter duck type that simply forwards all
        # received spans to a collection of SpanExporters.
        #
        # Can be used to export to multiple backends using the same
        # SpanProcessor like a {SimpleSpanProcessor} or a
        # {BatchSpanProcessor}.
        class MultiSpanExporter
          def initialize(span_exporters)
            @span_exporters = span_exporters.clone.freeze
          end

          # Called to export sampled {Span}s.
          #
          # @param [Enumerable<Span>] spans the list of sampled {Span}s to be
          #   exported.
          # @return [Integer] the result of the export.
          def export(spans)
            @span_exporters.inject(SUCCESS) do |result_code, span_exporter|
              merge_result_code(result_code, span_exporter.export(spans))
            rescue => e # rubocop:disable Style/RescueStandardError
              OpenTelemetry.logger.warn("exception raised by export - #{e}")
              FAILURE
            end
          end

          # Called when {TracerProvider#shutdown} is called, if this exporter is
          # registered to a {TracerProvider} object.
          def shutdown
            @span_exporters.each(&:shutdown)
          end

          private

          # Returns a merged error code, see the rules in the code.
          def merge_result_code(result_code, new_result_code)
            if result_code == SUCCESS && new_result_code == SUCCESS
              # If both errors are success then return success.
              SUCCESS
            else
              # At this point at least one of the code is FAILURE, so return FAILURE.
              FAILURE
            end
          end
        end
      end
    end
  end
end
