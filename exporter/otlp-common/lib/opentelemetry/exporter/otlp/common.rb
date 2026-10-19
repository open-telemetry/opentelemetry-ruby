# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common/utilities'
require 'opentelemetry/exporter/otlp/common/version'

require 'google/rpc/status_pb'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/logs/v1/logs_pb'
require 'opentelemetry/proto/metrics/v1/metrics_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/logs/v1/logs_service_pb'
require 'opentelemetry/proto/collector/metrics/v1/metrics_service_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      # Contains common functionality between the different OTLP export protocols
      module Common # rubocop:disable Metrics/ModuleLength
        extend self

        # As encoded elsr (ExportLogsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Logs::LogRecordData>] log_record_data
        #   the list of recorded {OpenTelemetry::SDK::Logs::LogRecordData} structs to
        #   be encoded.
        #
        # @return [String] returns an encoded ELSR of the provided log record data
        def as_encoded_elsr(log_record_data)
          Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.encode(as_elsr(log_record_data))
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Common#as_encoded_elsr')
          nil
        end

        # As elsr (ExportLogsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Logs::LogRecordData>] log_record_data
        #   the list of recorded {OpenTelemetry::SDK::Logs::LogRecordData} structs to
        #   be encoded.
        #
        # @return [Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest]
        #   returns an ELSR of the provided log record data
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

        # As encoded emsr (ExportMetricsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Metrics::MetricData>] metrics_data the
        #   list of recorded {OpenTelemetry::SDK::Metrics::MetricData} structs to be
        #   encoded.
        #
        # @return [String] returns an encoded EMSR of the provided metrics data
        def as_encoded_emsr(metrics_data)
          Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.encode(as_emsr(metrics_data))
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Common#as_encoded_emsr')
          nil
        end

        # As emsr (ExportMetricsServiceRequest)
        #
        # @param [Enumerable<OpenTelemetry::SDK::Metrics::MetricData>] metrics_data the
        #   list of recorded {OpenTelemetry::SDK::Metrics::MetricData} structs to be
        #   encoded.
        #
        # @return [Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest]
        #   returns an EMSR of the provided metrics data
        def as_emsr(metrics_data)
          Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.new(
            resource_metrics: metrics_data
                              .group_by(&:resource)
                              .map do |resource, scope_metrics|
                                Opentelemetry::Proto::Metrics::V1::ResourceMetrics.new(
                                  resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                                    attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                                  ),
                                  scope_metrics: scope_metrics
                                                 .group_by(&:instrumentation_scope)
                                                 .map do |instrumentation_scope, metrics|
                                                   Opentelemetry::Proto::Metrics::V1::ScopeMetrics.new(
                                                     scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                                                       name: instrumentation_scope.name,
                                                       version: instrumentation_scope.version
                                                     ),
                                                     metrics: metrics.map { |sd| as_otlp_metrics(sd) }
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

        # metrics_pb has following type of data: :gauge, :sum, :histogram, :exponential_histogram, :summary
        # current metric sdk only implements instrument: :counter -> :sum, :histogram -> :histogram, :gauge -> :gauge
        #
        # metrics [MetricData]
        def as_otlp_metrics(metrics)
          case metrics.instrument_kind
          when :observable_gauge, :gauge
            Opentelemetry::Proto::Metrics::V1::Metric.new(
              name: metrics.name,
              description: metrics.description,
              unit: metrics.unit,
              gauge: gauge_data_point(metrics)
            )

          when :counter, :up_down_counter, :observable_counter, :observable_up_down_counter
            Opentelemetry::Proto::Metrics::V1::Metric.new(
              name: metrics.name,
              description: metrics.description,
              unit: metrics.unit,
              sum: sum_data_point(metrics)
            )

          when :histogram
            histogram_data_point(metrics)

          end
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

        # Converts an SDK aggregation temporality symbol to its OTLP proto enum value.
        def as_otlp_aggregation_temporality(type)
          case type
          when :delta then Opentelemetry::Proto::Metrics::V1::AggregationTemporality::AGGREGATION_TEMPORALITY_DELTA
          when :cumulative then Opentelemetry::Proto::Metrics::V1::AggregationTemporality::AGGREGATION_TEMPORALITY_CUMULATIVE
          else Opentelemetry::Proto::Metrics::V1::AggregationTemporality::AGGREGATION_TEMPORALITY_UNSPECIFIED
          end
        end

        # Builds an OTLP Metric for gauge data points.
        def gauge_data_point(metrics)
          Opentelemetry::Proto::Metrics::V1::Gauge.new(
            data_points: metrics.data_points.map do |ndp|
              number_data_point(ndp)
            end
          )
        end

        # Builds an OTLP Metric for either histogram or exponential histogram data points.
        def histogram_data_point(metrics) # rubocop:disable Metrics/MethodLength
          return if metrics.data_points.empty?

          if metrics.data_points.first.instance_of?(OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogramDataPoint)
            Opentelemetry::Proto::Metrics::V1::Metric.new(
              name: metrics.name,
              description: metrics.description,
              unit: metrics.unit,
              exponential_histogram: Opentelemetry::Proto::Metrics::V1::ExponentialHistogram.new(
                aggregation_temporality: as_otlp_aggregation_temporality(metrics.aggregation_temporality),
                data_points: metrics.data_points.map do |ehdp|
                  exponential_histogram_data_point(ehdp)
                end
              )
            )
          elsif metrics.data_points.first.instance_of?(OpenTelemetry::SDK::Metrics::Aggregation::HistogramDataPoint)
            Opentelemetry::Proto::Metrics::V1::Metric.new(
              name: metrics.name,
              description: metrics.description,
              unit: metrics.unit,
              histogram: Opentelemetry::Proto::Metrics::V1::Histogram.new(
                aggregation_temporality: as_otlp_aggregation_temporality(metrics.aggregation_temporality),
                data_points: metrics.data_points.map do |hdp|
                  explicit_histogram_data_point(hdp)
                end
              )
            )
          end
        end

        # Converts a {HistogramDataPoint} to its OTLP proto representation.
        def explicit_histogram_data_point(hdp)
          Opentelemetry::Proto::Metrics::V1::HistogramDataPoint.new(
            attributes: hdp.attributes.map { |k, v| as_otlp_key_value(k, v) },
            start_time_unix_nano: hdp.start_time_unix_nano,
            time_unix_nano: hdp.time_unix_nano,
            count: hdp.count,
            sum: hdp.sum,
            bucket_counts: hdp.bucket_counts,
            explicit_bounds: hdp.explicit_bounds,
            exemplars: as_otlp_exemplars(hdp.exemplars),
            min: hdp.min,
            max: hdp.max,
            flags: hdp.flags
          )
        end

        # Converts an {ExponentialHistogramDataPoint} to its OTLP proto representation.
        def exponential_histogram_data_point(ehdp)
          Opentelemetry::Proto::Metrics::V1::ExponentialHistogramDataPoint.new(
            attributes: ehdp.attributes.map { |k, v| as_otlp_key_value(k, v) },
            start_time_unix_nano: ehdp.start_time_unix_nano,
            time_unix_nano: ehdp.time_unix_nano,
            count: ehdp.count,
            sum: ehdp.sum,
            scale: ehdp.scale,
            zero_count: ehdp.zero_count,
            positive: Opentelemetry::Proto::Metrics::V1::ExponentialHistogramDataPoint::Buckets.new(
              offset: ehdp.positive.offset,
              bucket_counts: ehdp.positive.counts
            ),
            negative: Opentelemetry::Proto::Metrics::V1::ExponentialHistogramDataPoint::Buckets.new(
              offset: ehdp.negative.offset,
              bucket_counts: ehdp.negative.counts
            ),
            flags: ehdp.flags,
            exemplars: as_otlp_exemplars(ehdp.exemplars),
            min: ehdp.min,
            max: ehdp.max,
            zero_threshold: ehdp.zero_threshold
          )
        end

        # Builds an OTLP Metric for sum data points.
        def sum_data_point(metrics)
          Opentelemetry::Proto::Metrics::V1::Sum.new(
            aggregation_temporality: as_otlp_aggregation_temporality(metrics.aggregation_temporality),
            data_points: metrics.data_points.map do |ndp|
              number_data_point(ndp)
            end,
            is_monotonic: metrics.is_monotonic
          )
        end

        # Converts a {NumberDataPoint} to its OTLP proto representation.
        def number_data_point(ndp)
          args = {
            attributes: ndp.attributes.map { |k, v| as_otlp_key_value(k, v) },
            start_time_unix_nano: ndp.start_time_unix_nano,
            time_unix_nano: ndp.time_unix_nano,
            exemplars: as_otlp_exemplars(ndp.exemplars),
            flags: ndp.flags
          }

          if ndp.value.is_a?(Float)
            args[:as_double] = ndp.value
          else
            args[:as_int] = ndp.value
          end

          Opentelemetry::Proto::Metrics::V1::NumberDataPoint.new(**args)
        end

        # Converts a list of SDK exemplars to their OTLP proto representation.
        def as_otlp_exemplars(exemplars)
          exemplars&.map { |ex| as_otlp_exemplar(ex) } || []
        end

        # Converts a single SDK exemplar to its OTLP proto representation.
        def as_otlp_exemplar(exemplar)
          args = {
            time_unix_nano: exemplar.time_unix_nano,
            span_id: exemplar.span_id,
            trace_id: exemplar.trace_id
          }

          # Add filtered_attributes if present
          args[:filtered_attributes] = exemplar.filtered_attributes.map { |k, v| as_otlp_key_value(k, v) } if exemplar.filtered_attributes

          # Set value based on type
          if exemplar.value.is_a?(Float)
            args[:as_double] = exemplar.value
          else
            args[:as_int] = exemplar.value
          end

          Opentelemetry::Proto::Metrics::V1::Exemplar.new(**args)
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

        def as_otlp_any_value(value)
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
