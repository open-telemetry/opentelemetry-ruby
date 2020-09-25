# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

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
        private_constant(:SUCCESS, :FAILURE)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        RETRY_COUNT = 5
        private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT)

        def initialize(endpoint: config_opt('OTEL_EXPORTER_OTLP_SPAN_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'localhost:55681/v1/trace'), # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
                       insecure: config_opt('OTEL_EXPORTER_OTLP_SPAN_INSECURE', 'OTEL_EXPORTER_OTLP_INSECURE', default: false),
                       certificate_file: config_opt('OTEL_EXPORTER_OTLP_SPAN_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                       headers: config_opt('OTEL_EXPORTER_OTLP_SPAN_HEADERS', 'OTEL_EXPORTER_OTLP_HEADERS'), # TODO: what format is expected here?
                       compression: config_opt('OTEL_EXPORTER_OTLP_SPAN_COMPRESSION', 'OTEL_EXPORTER_OTLP_COMPRESSION'),
                       timeout: config_opt('OTEL_EXPORTER_OTLP_SPAN_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10))
          raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" if invalid_url?("http://#{endpoint}")
          raise ArgumentError, "unsupported compression key #{compression}" unless compression.nil? || compression == 'gzip'
          raise ArgumentError, 'headers must be comma-separated k:v pairs or a Hash' unless valid_headers?(headers)

          uri = URI "http://#{endpoint}"
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = insecure.to_s.downcase == 'false'
          @http.ca_file = certificate_file unless certificate_file.nil?
          @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

          @path = uri.path
          @headers = case headers
                     when String then CSV.parse(headers, col_sep: ':', row_sep: ',').to_h
                     when Hash then headers
                     end
          @timeout = timeout.to_f # TODO: use this as a default timeout when we implement timeouts in https://github.com/open-telemetry/opentelemetry-ruby/pull/341
          @compression = compression

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

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
          @http.finish if @http.started?
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

          CSV.parse(headers, col_sep: ':', row_sep: ',').to_h
          true
        rescue ArgumentError
          false
        end

        def invalid_url?(url)
          return true if url.nil? || url.strip.empty?

          uri = URI(url)
          uri.path.nil? || uri.path.empty?
        rescue URI::InvalidURIError
          true
        end

        def send_bytes(bytes, timeout:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          retry_count = 0
          timeout ||= @timeout
          start_time = Time.now
          untraced do # rubocop:disable Metrics/BlockLength
            request = Net::HTTP::Post.new(@path)
            request.body = if @compression == 'gzip'
                             request.add_field('Content-Encoding', 'gzip')
                             Zlib.gzip(bytes)
                           else
                             bytes
                           end
            request.add_field('Content-Type', 'application/x-protobuf')
            @headers&.each { |key, value| request.add_field(key, value) }

            remaining_timeout = OpenTelemetry::SDK::Internal.maybe_timeout(timeout, start_time)
            return FAILURE if remaining_timeout.zero?

            @http.open_timeout = remaining_timeout
            @http.read_timeout = remaining_timeout
            @http.start unless @http.started?
            response = @http.request(request)

            case response
            when Net::HTTPOK
              response.body # Read and discard body
              SUCCESS
            when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
              response.body # Read and discard body
              redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1)
              FAILURE
            when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
              response.body # Read and discard body
              redo if backoff?(retry_count: retry_count += 1)
              FAILURE
            when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
              # TODO: decode the body as a google.rpc.Status Protobuf-encoded message when https://github.com/open-telemetry/opentelemetry-collector/issues/1357 is fixed.
              response.body # Read and discard body
              FAILURE
            when Net::HTTPRedirection
              @http.finish
              handle_redirect(response['location'])
              redo if backoff?(retry_after: 0, retry_count: retry_count += 1)
            else
              @http.finish
              FAILURE
            end
          rescue Net::OpenTimeout, Net::ReadTimeout
            retry if backoff?(retry_count: retry_count += 1)
            return FAILURE
          end
        end

        def handle_redirect(location)
          # TODO: figure out destination and reinitialize @http and @path
        end

        def untraced
          OpenTelemetry::Trace.with_span(OpenTelemetry::Trace::Span.new) { yield }
        end

        def backoff?(retry_after: nil, retry_count:)
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
            trace_state: span_data.tracestate,
            parent_span_id: span_data.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID ? nil : span_data.parent_span_id,
            name: span_data.name,
            kind: as_otlp_span_kind(span_data.kind),
            start_time_unix_nano: as_otlp_timestamp(span_data.start_timestamp),
            end_time_unix_nano: as_otlp_timestamp(span_data.end_timestamp),
            attributes: span_data.attributes&.map { |k, v| as_otlp_key_value(k, v) },
            dropped_attributes_count: span_data.total_recorded_attributes - span_data.attributes&.size.to_i,
            events: span_data.events&.map do |event|
              Opentelemetry::Proto::Trace::V1::Span::Event.new(
                time_unix_nano: as_otlp_timestamp(event.timestamp),
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
                trace_state: link.span_context.tracestate,
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

        def as_otlp_timestamp(timestamp)
          (timestamp.to_r * 1_000_000_000).to_i
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
