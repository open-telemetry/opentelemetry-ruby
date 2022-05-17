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
        class Exporter
          SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          def initialize(endpoint: config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'http://localhost:4317/v1/traces'),
                         timeout: config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                         metrics_reporter: nil)
            raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" if invalid_url?(endpoint)

            uri = URI(endpoint)

            @client = Opentelemetry::Proto::Collector::Trace::V1::TraceService::Stub.new(
              "#{uri.host}:#{uri.port}",
              :this_channel_is_insecure
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

          private

          def config_opt(*env_vars, default: nil)
            env_vars.each do |env_var|
              val = ENV[env_var]
              return val unless val.nil?
            end
            default
          end

          def invalid_url?(url)
            return true if url.nil? || url.strip.empty?

            URI(url)
            false
          rescue URI::InvalidURIError
            true
          end
        end
      end
    end
  end
end
