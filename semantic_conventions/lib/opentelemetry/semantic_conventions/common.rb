# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    module Common
      # A comparison between the actual size of the Span and the BatchSpanProcessor @max_queue_size
      OTEL_BSP_BUFFER_UTILIZATION = 'otel.bsp.buffer_utilization'

      # A count of spans that were permanently dropped
      OTEL_BSP_DROPPED_SPANS = 'otel.bsp.dropped_spans'

      # A count of errors in the BatchSpanProcessor
      OTEL_BSP_ERROR = 'otel.bsp.error'

      # A count of failed Span exports in the BatchSpanProcessor
      OTEL_BSP_EXPORT_FAILURE = 'otel.bsp.export.failure'

      # A count of sucessful Span exports in the BatchSpanProcessor
      OTEL_BSP_EXPORT_SUCCESS = 'otel.bsp.export.success'

      # A count of the total number of exported Spans in the BatchSpanProcessor
      OTEL_BSP_EXPORTED_SPANS = 'otel.bsp.exported_spans'

      # A count of dropped attributes
      OTEL_DROPPED_ATTRIBUTES_COUNT = 'otel.dropped_attributes_count'

      # A count of dropped events
      OTEL_DROPPED_EVENTS_COUNT = 'otel.dropped_events_count'

      # A count of dropped links
      OTEL_DROPPED_LINKS_COUNT = 'otel.dropped_links_count'

      # Identifies Jaeger failed trace exports
      OTEL_JAEGER_EXPORTER_FAILURE = 'otel.jaeger_exporter.failure'

      # Identifies the time it took to flush Spans to Jaeger
      OTEL_JAEGER_EXPORTER_REQUEST_DURATION = 'otel.jaeger_exporter.request_duration'
      
      # The name of the instrumentation scope
      # @note To be deprecated for otel.scope.name https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/mapping-to-non-otlp.md?plain=1#L43
      OTEL_LIBRARY_NAME = 'otel.library.name'

      # The version of the instrumentation scope
      # @note To be deprecated for otel.scope.version https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/mapping-to-non-otlp.md?plain=1#L44
      OTEL_LIBRARY_VERSION = 'otel.library.version'

      # A count of failed exports of spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests
      OTEL_OTLP_EXPORTER_FAILURE = 'otel.otlp_exporter.failure'
      
      # Compressed size of the message in bytes
      OTEL_OTLP_EXPORTER_MESSAGE_COMPRESSED_SIZE = 'otel.otlp_exporter.message.compressed_size'
      
      # Uncompressed size of the message in bytes
      OTEL_OTLP_EXPORTER_MESSAGE_UNCOMPRESSED_SIZE = 'otel.otlp_exporter.message.uncompressed_size'
      
      # Identififes the time it took to send the Spans over HTTP
      OTEL_OTLP_EXPORTER_REQUEST_DURATION = 'otel.otlp_exporter.request_duration'
      
      # The name of the instrumentation scope
      OTEL_SCOPE_NAME = 'otel.scope.name'

      # The version of the instrumentation scope
      OTEL_SCOPE_VERSION = 'otel.scope.version'

      # The value of the [status_code](https://github.com/open-telemetry/opentelemetry-specification/blob/main/semantic_conventions/trace/exporter/exporter.yaml)
      OTEL_STATUS_CODE = 'otel.status_code'

      # A count of failures when exporting Spans to Zipkin
      OTEL_ZIPKIN_EXPORTER_FAILURE = 'otel.zipkin_exporter.failure'

      # Identifies the time it took to flush Spans to Zipkin
      OTEL_ZIPKIN_EXPORTER_REQUEST_DURATION = 'otel.zipkin_exporter.request_duration'
    end
  end
end
