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
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(spans, timeout: nil)
            start_time = Time.now
            results = @span_exporters.map do |span_exporter|
              span_exporter.export(spans, timeout: Internal.maybe_timeout(timeout, start_time))
            rescue => e # rubocop:disable Style/RescueStandardError
              OpenTelemetry.logger.warn("exception raised by export - #{e}")
              FAILURE
            end
            results.uniq.max || SUCCESS
          end

          # Called when {TracerProvider#shutdown} is called, if this exporter is
          # registered to a {TracerProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            start_time = Time.now
            results = @span_exporters.map do |processor|
              remaining_timeout = Internal.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              processor.shutdown(timeout: remaining_timeout)
            end
            results.uniq.max
          end
        end
      end
    end
  end
end
