# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/exporter/otlp/common/version'

require 'google/rpc/status_pb'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      # Contains common functionality between the different OTLP export protocols
      module Common # rubocop:disable Metrics/ModuleLength
        extend self

        # As encoded etsr (ExportLogsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] log_record_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   encoded.
        #
        # @return [String] returns an encoded ELSR of the provided log record data
        def as_encoded_elsr(log_record_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
          Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.encode(as_elsr(log_record_data))
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Common#as_encoded_etsr')
          nil
        end

        # As elsr (ExportLogsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   encoded.
        #
        # @return [Opentelemetry::Proto::Collector::Trace::V1::ExportLogsServiceRequest]
        #   returns an ETSR of the provided span data
        def as_elsr(log_record_data)
          Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.new(
            resource_logs: log_record_data
                            .group_by(&:resource)
                            .map do |resource, log_record_datas|
                              Opentelemetry::Proto::Logs::V1::ResourceLogs.new(
                                resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                                  attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                                ),
                                scope_logs: log_record_datas
                                           .group_by(&:instrumentation_scope)
                                            .map do |il, lrd|
                                              Opentelemetry::Proto::Logs::V1::ScopeLogs.new(
                                                scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                                                  name: il.name,
                                                  version: il.version
                                                ),
                                                log_records: lrd.map { |lr| as_otlp_log_record(lr) }
                                              )
                                            end
                              )
                            end
          )
        end

        # As encoded etsr (ExportTraceServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   encoded.
        #
        # @return [String] returns an encoded ETSR of the provided span data
        def as_encoded_etsr(span_data)
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(as_etsr(span_data))
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Common#as_encoded_etsr')
          nil
        end

        # As etsr (ExportTraceServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   encoded.
        #
        # @return [Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest]
        #   returns an ETSR of the provided span data
        def as_etsr(span_data)
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
            resource_spans: span_data
                            .group_by(&:resource)
                            .map do |resource, span_datas|
                              Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
                                resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                                  attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                                ),
                                scope_spans: span_datas
                                             .group_by(&:instrumentation_scope)
                                             .map do |il, sds|
                                               Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                                                 scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                                                   name: il.name,
                                                   version: il.version
                                                 ),
                                                 spans: sds.map { |sd| as_otlp_span(sd) }
                                               )
                                             end
                              )
                            end
          )
        end

        private

        def as_otlp_log_record(log_record_data)
          Opentelemetry::Proto::Logs::V1::LogRecord.new(
            time_unix_nano: log_record_data.timestamp,
            observed_time_unix_nano: log_record_data.observed_timestamp,
            severity_number: log_record_data.severity_number,
            severity_text: log_record_data.severity_text,
            body: as_otlp_any_value(log_record_data.body),
            attributes: log_record_data.attributes&.map { |k, v| as_otlp_key_value(k, v) },
            dropped_attributes_count: log_record_data.dropped_attributes_count,
            event_name: log_record_data.event_name,
            flags: log_record_data.trace_flags.instance_variable_get(:@flags),
            trace_id: log_record_data.trace_id,
            span_id: log_record_data.span_id
          )
        end
        
        def as_otlp_span(span_data) # rubocop:disable Metrics/MethodLength
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
                attributes: link.attributes&.map { |k, v| as_otlp_key_value(k, v) },
                # TODO: track dropped_attributes_count in Span#trim_links
                flags: build_span_flags(link.span_context.remote?, link.span_context.trace_flags)
              )
            end,
            dropped_links_count: span_data.total_recorded_links - span_data.links&.size.to_i,
            status: span_data.status&.then do |status|
              Opentelemetry::Proto::Trace::V1::Status.new(
                code: as_otlp_status_code(status.code),
                message: status.description
              )
            end,
            flags: build_span_flags(span_data.parent_span_is_remote, span_data.trace_flags)
          )
        end

        # Builds span flags based on whether the parent span context is remote.
        # This follows the OTLP specification for span flags.
        def build_span_flags(parent_span_is_remote, base_flags)
          # Extract integer value from TraceFlags object if needed
          # Derive the low 8-bit W3C trace flags using the public API.
          base_flags_int =
            if base_flags.sampled?
              1
            else
              0
            end

          has_remote_mask = Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
          is_remote_mask = Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK

          flags = base_flags_int | has_remote_mask
          flags |= is_remote_mask if parent_span_is_remote
          flags
        end

        def as_otlp_status_code(code)
          case code
          when OpenTelemetry::Trace::Status::OK then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
          when OpenTelemetry::Trace::Status::ERROR then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
          else Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
          end
        end

        def as_otlp_span_kind(kind)
          case kind
          when :internal then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL
          when :server then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER
          when :client then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT
          when :producer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER
          when :consumer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER
          else Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED
          end
        end

        def as_otlp_key_value(key, value)
          key = OpenTelemetry::Common::Utilities.utf8_encode(key, placeholder: 'Encoding Error')
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value(value))
        rescue Encoding::UndefinedConversionError => e
          encoded_value = value.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�')
          OpenTelemetry.handle_error(exception: e, message: "encoding error for key #{key} and value #{encoded_value}")
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value('Encoding Error'))
        end

        def as_otlp_any_value(value) # rubocop:disable Metrics/CyclomaticComplexity
          result = Opentelemetry::Proto::Common::V1::AnyValue.new
          case value
          when String
            result.string_value = OpenTelemetry::Common::Utilities.utf8_encode(value, placeholder: value)
          when Integer
            result.int_value = value
          when Float
            result.double_value = value
          when true, false
            result.bool_value = value
          when Array
            values = value.map { |element| as_otlp_any_value(element) }
            result.array_value = Opentelemetry::Proto::Common::V1::ArrayValue.new(values: values)
          when Hash
           values = value.map { |k, v| as_otlp_key_value(k, v) }
            result.kvlist_value = Opentelemetry::Proto::Common::V1::KeyValueList.new(values: values)
          end
          result
        end
      end
    end
  end
end
