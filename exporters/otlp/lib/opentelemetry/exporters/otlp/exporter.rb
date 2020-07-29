# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'net/http'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

module OpenTelemetry
  module Exporters
    module OTLP
      # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
      class Exporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        OPEN_TIMEOUT = 5
        READ_TIMEOUT = 5
        RETRY_COUNT = 5
        PATH = '/v1/trace'
        private_constant(:KEEP_ALIVE_TIMEOUT, :OPEN_TIMEOUT, :READ_TIMEOUT, :RETRY_COUNT, :PATH)

        def initialize(host:,
                       port:,
                       path: PATH,
                       use_ssl: false,
                       keep_alive_timeout: KEEP_ALIVE_TIMEOUT,
                       open_timeout: OPEN_TIMEOUT,
                       read_timeout: READ_TIMEOUT,
                       retry_count: RETRY_COUNT)
          @http = Net::HTTP.new(host, port)
          @http.use_ssl = use_ssl
          @http.keep_alive_timeout = keep_alive_timeout
          @http.open_timeout = open_timeout
          @http.read_timeout = read_timeout

          @path = path
          @max_retry_count = retry_count
          @tracer = OpenTelemetry.tracer_provider.tracer

          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(span_data)
          return FAILURE if @shutdown

          send_bytes(encode(span_data))
        end

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        def shutdown
          @shutdown = true
          @http.finish if @http.started?
        end

        private

        def send_bytes(bytes)
          retry_count = 0
          untraced do
            request = Net::HTTP::Post.new(@path)
            request.body = bytes
            request.add_field('Content-Type', 'application/x-protobuf')
            # TODO: enable gzip when https://github.com/open-telemetry/opentelemetry-collector/issues/1344 is fixed.
            # request.add_field('Content-Encoding', 'gzip')
  
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
          location = response['location']
          location = URI(location).relative? ? (@uri + location).to_s : location
          initialize_http(location) # Assume this is our new destination from now on.
        end

        def untraced
          @tracer.with_span(OpenTelemetry::Trace::Span.new) { yield }
        end

        def backoff?(retry_after: nil, retry_count:, reason:)
          return false if retry_count > @max_retry_count

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
              rescue
                nil
              end
            sleep_interval = nil unless sleep_interval&.positive?
          end
          sleep_interval ||= rand(2**retry_count)

          sleep(sleep_interval)
          true
        end

        def encode(span_data)
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
            Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
              resource_spans: [
                Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
                  resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                    attributes: OpenTelemetry.tracer_provider.resource.label_enumerator.map { |key, value| as_otlp_key_value(key, value) },
                  ),
                  instrumentation_library_spans: span_data
                    .group_by { |sd| sd.instrumentation_library }
                    .map do |il, sds|
                      Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                        instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                          name: il.name,
                          version: il.version,
                        ),
                        spans: sds.map { |sd| as_otlp_span(sd) },
                      )
                    end,
                )
              ]
            )
          )
        end

        def as_otlp_span(span_data)
          Opentelemetry::Proto::Trace::V1::Span.new(
            trace_id: span_data.trace_id,
            span_id: span_data.span_id,
            trace_state: span_data.tracestate,
            parent_span_id: span_data.parent_span_id,
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
                attributes: event.attributes&.map { |k, v| as_otlp_key_value(k, v) },
                # TODO: track dropped_attributes_count in Span#append_event
              )
            end,
            dropped_events_count: span_data.total_recorded_events - span_data.events&.size.to_i,
            links: span_data.links&.map do |link|
              Opentelemetry::Proto::Trace::V1::Span::Link.new(
                trace_id: link.context.trace_id,
                span_id: link.context.span_id,
                trace_state: link.context.tracestate,
                attributes: link.attributes&.map { |k, v| as_otlp_key_value(k, v) },
                # TODO: track dropped_attributes_count in Span#trim_links
              )
            end,
            dropped_links_count: span_data.total_recorded_links - span_data.links&.size.to_i,
            status: span_data.status&.yield_self do |status|
              Opentelemetry::Proto::Trace::V1::Status.new(
                code: status.canonical_code, # TODO: verify that the Integer canonical code can be used here instead of the enum.
                message: status.description,
              )
            end,
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
          kv = Opentelemetry::Proto::Common::V1::KeyValue.new(key: key)
          kv.value = Opentelemetry::Proto::Common::V1::AnyValue.new
          case value
          when String
            kv.value.string_value = value
          when Integer
            kv.value.int_value = value
          when Float
            kv.value.double_value = value
          when true, false
            kv.value.bool_value = value
          # TODO: when Array
          end
          kv
        end
      end
    end
  end
end
