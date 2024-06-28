# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common'
require 'opentelemetry/sdk'
require 'grpc'

require 'google/rpc/status_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_services_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      module GRPC
        # An OpenTelemetry trace exporter that sends spans over GRPC.
        class TraceExporter
          SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          def initialize(endpoint: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'http://localhost:4317/v1/traces'),
                         timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                         certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                         client_certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                         client_key_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY', 'OTEL_EXPORTER_OTLP_CLIENT_KEY'),
                         metrics_reporter: nil)
            raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)

            uri = URI(endpoint)

            creds = if !client_key_file.nil? && !client_certificate_file.nil?
                      # Permits constructing with nil root cert.
                      ::GRPC::Core::ChannelCredentials.new(certificate_file, client_key_file, client_certificate_file)
                    elsif !certificate_file.nil?
                      ::GRPC::Core::ChannelCredentials.new(certificate_file)
                    else
                      :this_channel_is_insecure
                    end

            @client = Opentelemetry::Proto::Collector::Trace::V1::TraceService::Stub.new(
              "#{uri.host}:#{uri.port}",
              creds
            )

            @timeout = timeout.to_f
            @metrics_reporter = metrics_reporter || OpenTelemetry::SDK::Trace::Export::MetricsReporter
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

            @client.export(OpenTelemetry::Exporter::OTLP::Common.as_etsr(span_data))
            SUCCESS
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
            SUCCESS
          end
        end
      end
    end
  end
end
