# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common'
require 'opentelemetry/exporter/otlp/http/common'
require 'opentelemetry/sdk'
require 'net/http'
require 'zlib'

require 'google/rpc/status_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
        class TraceExporter # rubocop:disable Metrics/ClassLength
          SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          def initialize(**kwargs)
            params = kwargs.values.compact.any? ? OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(**kwargs) : nil

            @http = OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(params, 'TRACES', 'v1/traces')
            @shutdown = false
          end

          # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
          #
          # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
          #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(span_data, timeout: nil)
            return FAILURE if @shutdown

            result = @http.export_bytes(OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr(span_data), timeout: timeout)
            log_status(result.http_response_body) if !result.success && result.http_response_body
            result.success ? SUCCESS : FAILURE
          end

          # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
          # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
          # object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
          # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
          # object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          def shutdown(timeout: nil)
            @shutdown = true
            @http.finish if @http.started?
            SUCCESS
          end

          private

          def log_status(body)
            status = Google::Rpc::Status.decode(body)
            pool = ::Google::Protobuf::DescriptorPool.generated_pool
            details = status.details.filter_map do |detail|
              klass = pool.lookup(detail.type_name).msgclass
              detail.unpack(klass) if klass
            end
            OpenTelemetry.handle_error(message: "OTLP exporter received rpc.Status{message=#{status.message}, details=#{details}}")
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error decoding rpc.Status in OTLP::Exporter#log_status')
          end
        end
      end
    end
  end
end
