# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporters
    module Jaeger
      class Exporter
        # @api private
        class SpanEncoder
          def encoded_span(span_data) # rubocop:disable Metrics/AbcSize
            start_time = (span_data.start_timestamp.to_f * 1_000_000).to_i
            duration = (span_data.end_timestamp.to_f * 1_000_000).to_i - start_time

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
              'tags' => encoded_tags(span_data.attributes) + encoded_status(span_data.status) + encoded_kind(span_data.kind),
              'logs' => encoded_logs(span_data.events)
            )
          end

          private

          def encoded_kind(kind)
            @kind_map ||= {
              OpenTelemetry::Trace::SpanKind::SERVER => 'server',
              OpenTelemetry::Trace::SpanKind::CLIENT => 'client',
              OpenTelemetry::Trace::SpanKind::PRODUCER => 'producer',
              OpenTelemetry::Trace::SpanKind::CONSUMER => 'consumer'
            }.freeze

            value = @kind_map[kind]
            if value
              Array(
                Thrift::Tag.new(
                  KEY => 'span.kind',
                  TYPE => Thrift::TagType::STRING,
                  STRING => value
                )
              )
            else
              EMPTY_ARRAY
            end
          end

          def encoded_logs(events)
            events&.map do |event|
              Thrift::Log.new(
                'timestamp' => (event.timestamp.to_f * 1_000_000).to_i,
                'fields' => encoded_tags(event.attributes) + encoded_tags('name' => event.name)
              )
            end
          end

          def encoded_references(links)
            links&.map do |link|
              Thrift::SpanRef.new(
                'refType' => Thrift::SpanRefType::CHILD_OF,
                'traceIdLow' => int64(link.context.trace_id[16, 16]),
                'traceIdHigh' => int64(link.context.trace_id[0, 16]),
                'spanId' => int64(link.context.span_id)
              )
            end
          end

          def encoded_status(status)
            # TODO: OpenTracing doesn't specify how to report non-HTTP (i.e. generic) status.
            EMPTY_ARRAY
          end

          def encoded_tags(attributes)
            attributes&.map do |key, value|
              encoded_tag(key, value)
            end || EMPTY_ARRAY
          end

          def encoded_tag(key, value)
            @type_map ||= {
              LONG => Thrift::TagType::LONG,
              DOUBLE => Thrift::TagType::DOUBLE,
              STRING => Thrift::TagType::STRING,
              BOOL => Thrift::TagType::BOOL
            }.freeze

            value_key = case value
                        when Integer then LONG
                        when Float then DOUBLE
                        when String, Array then STRING
                        when false, true then BOOL
                        end
            value = value.to_json if value.is_a?(Array)
            Thrift::Tag.new(
              KEY => key,
              TYPE => @type_map[value_key],
              value_key => value
            )
          end

          def int64(byte_string)
            int = byte_string.unpack1('Q>')
            int < (1 << 63) ? int : int - (1 << 64)
          end
        end
      end
    end
  end
end
