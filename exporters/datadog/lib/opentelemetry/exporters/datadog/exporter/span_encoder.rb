# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'ddtrace/span'
require 'ddtrace/ext'
require 'ddtrace/contrib/redis/ext'
require 'opentelemetry/trace/status'

module OpenTelemetry
  module Exporters
    module DatadogOtel
      class Exporter
        # @api private
        class SpanEncoder
          DD_ORIGIN = "_dd_origin"
          AUTO_REJECT = 0
          AUTO_KEEP = 1
          USER_KEEP = 2
          SAMPLE_RATE_METRIC_KEY = "_sample_rate"
          SAMPLING_PRIORITY_KEY = "_sampling_priority_v1"
          
          INSTRUMENTATION_SPAN_TYPES = {
            "OpenTelemetry::Adapters::Ethon": Datadog::Ext::HTTP::TYPE_OUTBOUND,
            "OpenTelemetry::Adapters::Excon": Datadog::Ext::HTTP::TYPE_OUTBOUND,
            "OpenTelemetry::Adapters::Faraday": Datadog::Ext::HTTP::TYPE_OUTBOUND,
            "OpenTelemetry::Adapters::Net::HTTP": Datadog::Ext::HTTP::TYPE_OUTBOUND,
            "OpenTelemetry::Adapters::Rack": Datadog::Ext::HTTP::TYPE_INBOUND,
            "OpenTelemetry::Adapters::Redis": Datadog::Contrib::Redis::Ext::TYPE,
            "OpenTelemetry::Adapters::RestClient": Datadog::Ext::HTTP::TYPE_OUTBOUND,
            "OpenTelemetry::Adapters::Sidekiq": Datadog::Ext::AppTypes::WORKER,
            "OpenTelemetry::Adapters::Sinatra": Datadog::Ext::HTTP::TYPE_INBOUND
          }

          def translate_to_datadog(otel_spans, service) # rubocop:disable Metrics/AbcSize
            datadog_spans = []
            otel_spans.each do |span|
              trace_id, span_id, parent_id = get_trace_ids(span)
              span_type = get_span_type(span)

              datadog_span = Datadog::Span.new(nil, span.name, {
                service: service, 
                trace_id: trace_id,
                span_id: span_id,
                parent_id: parent_id,
                resource: span.name,
                span_type: span_type
              })

              datadog_span.start_time = span.start_timestamp
              datadog_span.end_time = span.end_timestamp

              # set span.error, span tag error.msg/error.type
              if span.status.canonical_code != OpenTelemetry::Trace::Status::OK
                datadog_span.error = 1

                if span.status.description
                  exception_type, exception_value = get_exception_info(span)

                  datadog_span.set_tag("error.type", exception_type)
                  datadog_span.set_tag("error.msg", exception_value)
                end
              end
              
              #set tags
              datadog_span.set_tags(span.attributes)

              #add origin to root span
              origin = _get_origin(span)
              if origin and parent_id == 0:
                  datadog_span.set_tag(DD_ORIGIN, origin)

              #define sampling rate metric
              # sampling_rate = _get_sampling_rate(span)
              # if sampling_rate is not None:
              #     datadog_span.set_metric(SAMPLE_RATE_METRIC_KEY, sampling_rate)


              datadog_spans << datadog_span
              # puts datadog_span
            end

            datadog_spans
          end

          private

          def get_trace_ids(span)
            trace_id = int64(span.trace_id[0,16])
            span_id = int64(span.span_id)
            parent_id = int64(span.parent_span_id)

            [trace_id, span_id, parent_id]
          end

          def get_span_type(span)
            # Get Datadog span type
            
            instrumentation_name = if span.instrumentation_library 
              span.instrumentation_library.name 
            else
              nil
            end

            span_type = INSTRUMENTATION_SPAN_TYPES[instrumentation_name]
            return span_type
          end

          def get_exc_info(span)
            # Parse span status description for exception type and value
            exc_type, exc_val = span.status.description.split(":", 1)
            [exc_type, exc_val.strip]
          end

          def int64(hex_string)
            int = hex_string.to_i(16)
            int < (1 << 63) ? int : int - (1 << 64)
          end
        end
      end
    end
  end
end