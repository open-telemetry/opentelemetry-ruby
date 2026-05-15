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
        class TraceExporter # rubocop:disable Metrics/ClassLength
          SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          # Default retry count for transient errors.
          RETRY_COUNT = 5
          private_constant(:RETRY_COUNT)

          def initialize(endpoint: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'http://localhost:4317/v1/traces'),
                         timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                         certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                         client_certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                         client_key_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY', 'OTEL_EXPORTER_OTLP_CLIENT_KEY'),
                         metrics_reporter: nil)
            raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)

            uri = URI(endpoint)

            root_cert = File.read(certificate_file) unless certificate_file.nil?
            client_cert = File.read(client_certificate_file) unless client_certificate_file.nil?
            client_key = File.read(client_key_file) unless client_key_file.nil?

            creds = if !client_key.nil? && !client_cert.nil?
                      # Permits constructing with nil root cert.
                      ::GRPC::Core::ChannelCredentials.new(root_cert, client_key, client_cert)
                    elsif !root_cert.nil?
                      ::GRPC::Core::ChannelCredentials.new(root_cert)
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

            send_spans(span_data, timeout: timeout)
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

          def send_spans(span_data, timeout:) # rubocop:disable Metrics/MethodLength
            retry_count = 0
            timeout ||= @timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp

            loop do
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return FAILURE if remaining_timeout.zero?

              request = OpenTelemetry::Exporter::OTLP::Common.as_etsr(span_data)
              @client.export(request, deadline: Time.now + remaining_timeout)
              return SUCCESS
            rescue ::GRPC::DeadlineExceeded
              retry if backoff?(retry_count: retry_count += 1, reason: 'deadline_exceeded')
              return FAILURE
            rescue ::GRPC::Unavailable
              retry if backoff?(retry_count: retry_count += 1, reason: 'unavailable')
              return FAILURE
            rescue ::GRPC::Cancelled
              retry if backoff?(retry_count: retry_count += 1, reason: 'cancelled')
              return FAILURE
            rescue ::GRPC::ResourceExhausted
              retry if backoff?(retry_count: retry_count += 1, reason: 'resource_exhausted')
              return FAILURE
            rescue ::GRPC::Aborted
              retry if backoff?(retry_count: retry_count += 1, reason: 'aborted')
              return FAILURE
            rescue ::GRPC::Internal
              retry if backoff?(retry_count: retry_count += 1, reason: 'internal')
              return FAILURE
            rescue ::GRPC::DataLoss
              retry if backoff?(retry_count: retry_count += 1, reason: 'data_loss')
              return FAILURE
            rescue ::GRPC::Unauthenticated => e
              OpenTelemetry.handle_error(exception: e, message: 'authentication error in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: 'unauthenticated' })
              return FAILURE
            rescue ::GRPC::PermissionDenied => e
              OpenTelemetry.handle_error(exception: e, message: 'permission denied in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: 'permission_denied' })
              return FAILURE
            rescue ::GRPC::InvalidArgument => e
              OpenTelemetry.handle_error(exception: e, message: 'invalid argument in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: 'invalid_argument' })
              return FAILURE
            rescue ::GRPC::NotFound => e
              OpenTelemetry.handle_error(exception: e, message: 'not found in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: 'not_found' })
              return FAILURE
            rescue ::GRPC::Unimplemented => e
              OpenTelemetry.handle_error(exception: e, message: 'unimplemented in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: 'unimplemented' })
              return FAILURE
            rescue ::GRPC::BadStatus => e
              OpenTelemetry.handle_error(exception: e, message: "gRPC error in OTLP::GRPC::TraceExporter#send_spans: #{e.code} - #{e.details}")
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: e.code.to_s })
              return FAILURE
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::GRPC::TraceExporter#send_spans')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: e.class.to_s })
              return FAILURE
            end
          end

          def backoff?(retry_count:, reason:)
            @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { reason: reason })
            return false if retry_count > RETRY_COUNT

            sleep_interval = rand(2**retry_count)
            sleep(sleep_interval)
            true
          end
        end
      end
    end
  end
end
