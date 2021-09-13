# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'
require 'opentelemetry/sdk'
require 'net/http'
require 'csv'
require 'zlib'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
      class Exporter # rubocop:disable Metrics/ClassLength
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        TIMEOUT = OpenTelemetry::SDK::Trace::Export::TIMEOUT
        private_constant(:SUCCESS, :FAILURE, :TIMEOUT)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        RETRY_COUNT = 5
        WRITE_TIMEOUT_SUPPORTED = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')
        private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT, :WRITE_TIMEOUT_SUPPORTED)

        def self.ssl_verify_mode
          if ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER')
            OpenSSL::SSL::VERIFY_PEER
          elsif ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE')
            OpenSSL::SSL::VERIFY_NONE
          else
            OpenSSL::SSL::VERIFY_PEER
          end
        end

        def initialize(endpoint: config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'https://localhost:4317/v1/traces'), # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
                       certificate_file: config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                       ssl_verify_mode: Exporter.ssl_verify_mode,
                       headers: config_opt('OTEL_EXPORTER_OTLP_TRACES_HEADERS', 'OTEL_EXPORTER_OTLP_HEADERS'),
                       compression: config_opt('OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', 'OTEL_EXPORTER_OTLP_COMPRESSION'),
                       timeout: config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                       metrics_reporter: nil)
          raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" if invalid_url?(endpoint)
          raise ArgumentError, "unsupported compression key #{compression}" unless compression.nil? || compression == 'gzip'
          raise ArgumentError, 'headers must be comma-separated k=v pairs or a Hash' unless valid_headers?(headers)

          @uri = if endpoint == ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
                   URI("#{endpoint}/v1/traces")
                 else
                   URI(endpoint)
                 end

          @http = Net::HTTP.new(@uri.host, @uri.port)
          @http.use_ssl = @uri.scheme == 'https'
          @http.verify_mode = ssl_verify_mode
          @http.ca_file = certificate_file unless certificate_file.nil?
          @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

          @path = @uri.path
          @headers = case headers
                     when String then CSV.parse(headers, col_sep: '=', row_sep: ',').to_h
                     when Hash then headers
                     end
          @timeout = timeout.to_f
          @compression = compression
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

          send_bytes(encode(span_data), timeout: timeout)
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

        def config_opt(*env_vars, default: nil)
          env_vars.each do |env_var|
            val = ENV[env_var]
            return val unless val.nil?
          end
          default
        end

        def valid_headers?(headers)
          return true if headers.nil? || headers.is_a?(Hash)
          return false unless headers.is_a?(String)

          CSV.parse(headers, col_sep: '=', row_sep: ',').to_h
          true
        rescue ArgumentError
          false
        end

        def invalid_url?(url)
          return true if url.nil? || url.strip.empty?

          URI(url)
          false
        rescue URI::InvalidURIError
          true
        end

        # The around_request is a private method that provides an extension
        # point for the exporters network calls. The default behaviour
        # is to not trace these operations.
        #
        # An example use case would be to prepend a patch, or extend this class
        # and override this method's behaviour to explicitly trace the HTTP request.
        # This would allow you to trace your export pipeline.
        def around_request
          OpenTelemetry::Common::Utilities.untraced { yield }
        end

        def send_bytes(bytes, timeout:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          retry_count = 0
          timeout ||= @timeout
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          around_request do # rubocop:disable Metrics/BlockLength
            request = Net::HTTP::Post.new(@path)
            request.body = if @compression == 'gzip'
                             request.add_field('Content-Encoding', 'gzip')
                             Zlib.gzip(bytes)
                           else
                             bytes
                           end
            request.add_field('Content-Type', 'application/x-protobuf')
            @headers&.each { |key, value| request.add_field(key, value) }

            remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
            return TIMEOUT if remaining_timeout.zero?

            @http.open_timeout = remaining_timeout
            @http.read_timeout = remaining_timeout
            @http.write_timeout = remaining_timeout if WRITE_TIMEOUT_SUPPORTED
            @http.start unless @http.started?
            response = measure_request_duration { @http.request(request) }

            case response
            when Net::HTTPOK
              response.body # Read and discard body
              SUCCESS
            when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
              response.body # Read and discard body
              redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
              response.body # Read and discard body
              redo if backoff?(retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
              # TODO: decode the body as a google.rpc.Status Protobuf-encoded message when https://github.com/open-telemetry/opentelemetry-collector/issues/1357 is fixed.
              response.body # Read and discard body
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => response.code })
              FAILURE
            when Net::HTTPRedirection
              @http.finish
              handle_redirect(response['location'])
              redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
            else
              @http.finish
              FAILURE
            end
          rescue Net::OpenTimeout, Net::ReadTimeout
            retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
            return FAILURE
          rescue OpenSSL::SSL::SSLError
            retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
            return FAILURE
          rescue SocketError
            retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
            return FAILURE
          rescue SystemCallError => e
            retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
            return FAILURE
          rescue EOFError
            retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
            return FAILURE
          end
        ensure
          # Reset timeouts to defaults for the next call.
          @http.open_timeout = @timeout
          @http.read_timeout = @timeout
          @http.write_timeout = @timeout if WRITE_TIMEOUT_SUPPORTED
        end

        def handle_redirect(location)
          # TODO: figure out destination and reinitialize @http and @path
        end

        def measure_request_duration
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            response = yield
          ensure
            stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            duration_ms = 1000.0 * (stop - start)
            @metrics_reporter.record_value('otel.otlp_exporter.request_duration',
                                           value: duration_ms,
                                           labels: { 'status' => response&.code || 'unknown' })
          end
        end

        def backoff?(retry_after: nil, retry_count:, reason:)
          @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => reason })
          return false if retry_count > RETRY_COUNT

          sleep_interval = nil
          unless retry_after.nil?
            sleep_interval =
              begin
                Integer(retry_after)
              rescue ArgumentError
                nil
              end
            sleep_interval ||=
              begin
                Time.httpdate(retry_after) - Time.now
              rescue # rubocop:disable Style/RescueStandardError
                nil
              end
            sleep_interval = nil unless sleep_interval&.positive?
          end
          sleep_interval ||= rand(2**retry_count)

          sleep(sleep_interval)
          true
        end

        def encode(span_data) # rubocop:disable Metrics/MethodLength
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
            Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
              resource_spans: span_data
                .group_by(&:resource)
                .map do |resource, span_datas|
                  Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
                    resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                      attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                    ),
                    instrumentation_library_spans: span_datas
                      .group_by(&:instrumentation_library)
                      .map do |il, sds|
                        Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                          instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                            name: il.name,
                            version: il.version
                          ),
                          spans: sds.map { |sd| as_otlp_span(sd) }
                        )
                      end
                  )
                end
            )
          )
        end

        def as_otlp_span(span_data) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          Opentelemetry::Proto::Trace::V1::Span.new(
            trace_id: span_data.trace_id,
            span_id: span_data.span_id,
            trace_state: span_data.tracestate.to_s,
            parent_span_id: span_data.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID ? nil : span_data.parent_span_id,
            name: span_data.name,
            kind: as_otlp_span_kind(span_data.kind),
            start_time_unix_nano: span_data.start_timestamp,
            end_time_unix_nano: span_data.end_timestamp,
            attributes: span_data.attributes&.map { |k, v| as_otlp_key_value(k, v) },
            dropped_attributes_count: span_data.total_recorded_attributes - span_data.attributes&.size.to_i,
            events: span_data.events&.map do |event|
              Opentelemetry::Proto::Trace::V1::Span::Event.new(
                time_unix_nano: event.timestamp,
                name: event.name,
                attributes: event.attributes&.map { |k, v| as_otlp_key_value(k, v) }
                # TODO: track dropped_attributes_count in Span#append_event
              )
            end,
            dropped_events_count: span_data.total_recorded_events - span_data.events&.size.to_i,
            links: span_data.links&.map do |link|
              Opentelemetry::Proto::Trace::V1::Span::Link.new(
                trace_id: link.span_context.trace_id,
                span_id: link.span_context.span_id,
                trace_state: link.span_context.tracestate.to_s,
                attributes: link.attributes&.map { |k, v| as_otlp_key_value(k, v) }
                # TODO: track dropped_attributes_count in Span#trim_links
              )
            end,
            dropped_links_count: span_data.total_recorded_links - span_data.links&.size.to_i,
            status: span_data.status&.yield_self do |status|
              # TODO: fix this based on spec update.
              Opentelemetry::Proto::Trace::V1::Status.new(
                code: status.code == OpenTelemetry::Trace::Status::ERROR ? Opentelemetry::Proto::Trace::V1::Status::StatusCode::UnknownError : Opentelemetry::Proto::Trace::V1::Status::StatusCode::Ok,
                message: status.description
              )
            end
          )
        end

        def as_otlp_span_kind(kind)
          case kind
          when :internal then Opentelemetry::Proto::Trace::V1::Span::SpanKind::INTERNAL
          when :server then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SERVER
          when :client then Opentelemetry::Proto::Trace::V1::Span::SpanKind::CLIENT
          when :producer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::PRODUCER
          when :consumer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::CONSUMER
          else Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED
          end
        end

        def as_otlp_key_value(key, value)
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value(value))
        rescue Encoding::UndefinedConversionError => e
          encoded_value = value.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�')
          OpenTelemetry.handle_error(exception: e, message: "encoding error for key #{key} and value #{encoded_value}")
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value('Encoding Error'))
        end

        def as_otlp_any_value(value)
          result = Opentelemetry::Proto::Common::V1::AnyValue.new
          case value
          when String
            result.string_value = value
          when Integer
            result.int_value = value
          when Float
            result.double_value = value
          when true, false
            result.bool_value = value
          when Array
            values = value.map { |element| as_otlp_any_value(element) }
            result.array_value = Opentelemetry::Proto::Common::V1::ArrayValue.new(values: values)
          end
          result
        end
      end
    end
  end
end
