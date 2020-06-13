# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'net/http'

module OpenTelemetry
  module Exporters
    module OTLP
      # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
      class Exporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILED = OpenTelemetry::SDK::Trace::Export::FAILED
        private_constant(:SUCCESS, :FAILED)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        OPEN_TIMEOUT = 5
        READ_TIMEOUT = 5
        PATH = '/v1/traces'
        private_constant(:KEEP_ALIVE_TIMEOUT, :OPEN_TIMEOUT, :READ_TIMEOUT, :PATH)

        def initialize(host:,
                       port:,
                       path: PATH,
                       use_ssl: false,
                       keep_alive_timeout: KEEP_ALIVE_TIMEOUT,
                       open_timeout: OPEN_TIMEOUT,
                       read_timeout: READ_TIMEOUT)
          @http = Net::HTTP.new(host, port)
          @http.use_ssl = use_ssl
          @http.keep_alive_timeout = keep_alive_timeout
          @http.open_timeout = open_timeout
          @http.read_timeout = read_timeout

          @path = path

          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(span_data)
          return FAILED if @shutdown

          etsr = wrap(span_data)
          bytes = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(etsr)

          # Send
          request = Net::HTTP::Post.new(@path)
          request.body = bytes
          request.add_field('Content-Type', 'application/x-protobuf')
          request.add_field('Content-Encoding', 'gzip')

          response = untraced do # TODO: how to 'untrace'?
            @http.start unless @http.started?
            @http.request(request)
          rescue Net::OpenTimeout, Net::ReadTimeout
            return FAILED # TODO: exponential backoff/retry with jitter.
          end
          
          case response
          when Net::HTTPOK
            SUCCESS
          else # TODO: distinguish errors and retry if appropriate
            FAILED
          end
        end

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        def shutdown
          @shutdown = true
          @http.finish if @http.started? # TODO: is shutdown called concurrently with export?
        end

        private

        def wrap(span_data)
          rs = Opentelemetry::Proto::Trace::V1::ResourceSpans.new
          rs.resource = OpenTelemetry.tracer_provider.resource
          span_data
            .group_by { |sd| sd.instrumentation_library }
            .each do |il, sds|
              ils = Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new
              ils.instrumentation_library = Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new
              ils.instrumentation_library.name = il.name
              ils.instrumentation_library.version = il.version
              sds.each { |sd| ils.spans.push(as_otlp_span(sd)) }
              rs.instrumentation_library_spans.push(ils)
            end
          etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new
          etsr.resource_spans.push(rs)
          etsr
        end

        def as_otlp_span(span_data)
          span = Opentelemetry::Proto::Trace::V1::Span.new
          span.trace_id = span_data.trace_id
          span.span_id = span_data.span_id
          span.trace_state = span_data.trace_state # TODO: add tracestate to SpanData
          span.parent_span_id = span_data.parent_span_id
          span.name = span_data.name
          span.kind = as_otlp_span_kind(span_data.kind)
          span.start_time_unix_nano = as_otlp_timestamp(span_data.start_timestamp)
          span.end_time_unix_nano = as_otlp_timestamp(span_data.end_timestamp)
          span_data.attributes&.each { |k, v| span.attributes.push(as_otlp_attribute(k, v)) }
          span.dropped_attributes_count = span_data.total_recorded_attributes - span_data.attributes.size
          span_data.events&.each { |event| span.events.push(as_otlp_event(event)) }
          span.dropped_events_count = span_data.total_recorded_events - span_data.events.size
          span_data.links&.each { |link| span.links.push(as_otlp_link(link)) }
          span.dropped_links_count = span_data.total_recorded_links - span_data.links.size
          span.status = as_otlp_status(span_data.status)
          span
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

        def as_otlp_attribute(key, value)
          kv = Opentelemetry::Proto::Common::V1::AttributeKeyValue.new
          kv.key = key
          case value
          when String
            kv.string_value = value
            kv.type = Opentelemetry::Proto::Common::V1::AttributeKeyValue::ValueType::STRING
          when Integer
            kv.int_value = value
            kv.type = Opentelemetry::Proto::Common::V1::AttributeKeyValue::ValueType::INT
          when Float
            kv.double_value = value
            kv.type = Opentelemetry::Proto::Common::V1::AttributeKeyValue::ValueType::DOUBLE
          when true, false
            kv.bool_value = value
            kv.type = Opentelemetry::Proto::Common::V1::AttributeKeyValue::ValueType::BOOL
          # TODO: when Array
          end
          kv
        end

        def as_otlp_event(event)
          e = Opentelemetry::Proto::Trace::V1::Span::Event.new
          e.time_unix_nano = as_otlp_timestamp(event.timestamp)
          e.name = event.name
          event.attributes&.each { |k, v| e.attributes.push(as_otlp_attribute(k, v)) }
          # TODO: enforcement of max_attributes_per_event -> dropped_attributes_count
          e
        end

        def as_otlp_link(link)
          l = Opentelemetry::Proto::Trace::V1::Span::Link.new
          l.trace_id = link.context.trace_id
          l.span_id = link.context.span_id
          l.trace_state = link.context.tracestate
          link.attributes&.each { |k, v| l.attributes.push(as_otlp_attribute(k, v)) }
          # TODO: enforcement of max_attributes_per_link -> dropped_attributes_count
          l
        end

        def as_otlp_status(status)
          # TODO: status "opentelemetry.proto.trace.v1.Status"
        end
      end
    end
  end
end
