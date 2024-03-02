# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Jaeger
      # @api private
      module Encoder # rubocop:disable Metrics/ModuleLength
        extend self

        EMPTY_ARRAY = [].freeze
        LONG = Thrift::Tag::FIELDS[Thrift::Tag::VLONG][:name]
        DOUBLE = Thrift::Tag::FIELDS[Thrift::Tag::VDOUBLE][:name]
        STRING = Thrift::Tag::FIELDS[Thrift::Tag::VSTR][:name]
        BOOL = Thrift::Tag::FIELDS[Thrift::Tag::VBOOL][:name]
        KEY = Thrift::Tag::FIELDS[Thrift::Tag::KEY][:name]
        TYPE = Thrift::Tag::FIELDS[Thrift::Tag::VTYPE][:name]
        TYPE_MAP = {
          LONG => Thrift::TagType::LONG,
          DOUBLE => Thrift::TagType::DOUBLE,
          STRING => Thrift::TagType::STRING,
          BOOL => Thrift::TagType::BOOL
        }.freeze
        KIND_MAP = {
          OpenTelemetry::Trace::SpanKind::SERVER => 'server',
          OpenTelemetry::Trace::SpanKind::CLIENT => 'client',
          OpenTelemetry::Trace::SpanKind::PRODUCER => 'producer',
          OpenTelemetry::Trace::SpanKind::CONSUMER => 'consumer'
        }.freeze
        DEFAULT_SERVICE_NAME = OpenTelemetry::SDK::Resources::Resource.default.attribute_enumerator.find { |k, _| k == 'service.name' }&.last || 'unknown_service'
        private_constant(:EMPTY_ARRAY, :LONG, :DOUBLE, :STRING, :BOOL, :KEY, :TYPE, :TYPE_MAP, :KIND_MAP, :DEFAULT_SERVICE_NAME)

        def encoded_process(resource)
          service_name = DEFAULT_SERVICE_NAME
          tags = resource&.attribute_enumerator&.reject do |key, value|
            service_name = value if key == 'service.name'
            key == 'service.name'
          end
          tags = encoded_tags(tags)
          Thrift::Process.new('serviceName' => service_name, 'tags' => tags)
        end

        def encoded_tags(attributes)
          attributes&.map do |key, value|
            encoded_tag(key, value)
          end || EMPTY_ARRAY
        end

        def encoded_tag(key, value)
          value_key = case value
                      when Integer then LONG
                      when Float then DOUBLE
                      when String, Array then STRING
                      when false, true then BOOL
                      end
          value = value.to_json if value.is_a?(Array)
          Thrift::Tag.new(
            KEY => key,
            TYPE => TYPE_MAP[value_key],
            value_key => value
          )
        end

        def encoded_span(span_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
          start_time = span_data.start_timestamp / 1_000
          duration = span_data.end_timestamp / 1_000 - start_time

          tags = encoded_tags(span_data.attributes) +
                 encoded_status(span_data.status) +
                 encoded_kind(span_data.kind) +
                 encoded_instrumentation_scope(span_data.instrumentation_scope)

          dropped_attributes_count = span_data.total_recorded_attributes - span_data.attributes&.size.to_i
          dropped_events_count = span_data.total_recorded_events - span_data.events&.size.to_i
          dropped_links_count = span_data.total_recorded_links - span_data.links&.size.to_i

          tags << encoded_tag('otel.dropped_attributes_count', dropped_attributes_count) if dropped_attributes_count.positive?
          tags << encoded_tag('otel.dropped_events_count', dropped_events_count) if dropped_events_count.positive?
          tags << encoded_tag('otel.dropped_links_count', dropped_links_count) if dropped_links_count.positive?

          Thrift::Span.new(
            'traceIdLow' => int64(span_data.trace_id[8, 8]),
            'traceIdHigh' => int64(span_data.trace_id[0, 8]),
            'spanId' => int64(span_data.span_id),
            'parentSpanId' => int64(span_data.parent_span_id),
            'operationName' => span_data.name,
            'references' => encoded_references(span_data.links),
            'flags' => span_data.trace_flags.sampled? ? 1 : 0,
            'startTime' => start_time,
            'duration' => duration,
            'tags' => tags,
            'logs' => encoded_logs(span_data.events)
          )
        end

        def encoded_kind(kind)
          value = KIND_MAP[kind]
          return EMPTY_ARRAY unless value

          Array(
            Thrift::Tag.new(
              KEY => 'span.kind',
              TYPE => Thrift::TagType::STRING,
              STRING => value
            )
          )
        end

        def encoded_logs(events)
          events&.map do |event|
            Thrift::Log.new(
              'timestamp' => event.timestamp / 1_000,
              'fields' => encoded_tags(event.attributes) + encoded_tags('name' => event.name)
            )
          end
        end

        def encoded_references(links)
          links&.map do |link|
            Thrift::SpanRef.new(
              'refType' => Thrift::SpanRefType::FOLLOWS_FROM,
              'traceIdLow' => int64(link.span_context.trace_id[8, 8]),
              'traceIdHigh' => int64(link.span_context.trace_id[0, 8]),
              'spanId' => int64(link.span_context.span_id)
            )
          end
        end

        def encoded_status(status)
          return EMPTY_ARRAY unless status&.code == OpenTelemetry::Trace::Status::ERROR

          Array(
            Thrift::Tag.new(
              KEY => 'error',
              TYPE => Thrift::TagType::BOOL,
              BOOL => true
            )
          )
        end

        def encoded_instrumentation_scope(instrumentation_scope)
          return EMPTY_ARRAY unless instrumentation_scope

          tags = []
          if instrumentation_scope.name
            tags << encoded_tag('otel.scope.name', instrumentation_scope.name)
            tags << encoded_tag('otel.library.name', instrumentation_scope.name)
          end

          if instrumentation_scope.version
            tags << encoded_tag('otel.scope.version', instrumentation_scope.version)
            tags << encoded_tag('otel.library.version', instrumentation_scope.version)
          end

          tags
        end

        def int64(byte_string)
          int = byte_string.unpack1('Q>')
          int < (1 << 63) ? int : int - (1 << 64)
        end
      end
    end
  end
end
