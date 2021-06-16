# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # Implementation of the SpanExporter duck type that simply forwards all
        # received SpanDatas to a collection of SpanExporters.
        #
        # Can be used to export to multiple backends using the same
        # SpanProcessor like a {SimpleSpanProcessor} or a
        # {BatchSpanProcessor}.
        class MultiSpanExporter
          def initialize(span_exporters)
            @span_exporters = span_exporters.clone.freeze
          end

          # Called to export sampled {SpanData} structs.
          #
          # @param [Enumerable<SpanData>] span_data the
          #   list of recorded {SpanData} structs to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(spans, timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @span_exporters.map do |span_exporter|
              span_exporter.export(spans, timeout: OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time))
            rescue => e # rubocop:disable Style/RescueStandardError
              OpenTelemetry.logger.warn("exception raised by export - #{e}")
              FAILURE
            end
            results.uniq.max || SUCCESS
          end

          # Called when {TracerProvider#force_flush} is called, if this exporter is
          # registered to a {TracerProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @span_exporters.map do |span_exporter|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              span_exporter.force_flush(timeout: remaining_timeout)
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
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @span_exporters.map do |span_exporter|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              span_exporter.shutdown(timeout: remaining_timeout)
            end
            results.uniq.max || SUCCESS
          end
        end
      end
    end
  end
end
