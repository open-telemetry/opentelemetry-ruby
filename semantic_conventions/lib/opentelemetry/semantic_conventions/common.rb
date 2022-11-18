# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    module Common
      # A count of dropped attributes
      OTEL_DROPPED_ATTRIBUTES_COUNT = 'otel.dropped_attributes_count'

      # A count of dropped events
      OTEL_DROPPED_EVENTS_COUNT = 'otel.dropped_events_count'

      # A count of dropped links
      OTEL_DROPPED_LINKS_COUNT = 'otel.dropped_links_count'

      # The name of the instrumentation scope
      # @note To be deprecated for otel.scope.name https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/mapping-to-non-otlp.md?plain=1#L43
      OTEL_LIBRARY_NAME = 'otel.library.name'

      # The version of the instrumentation scope
      # @note To be deprecated for otel.scope.version https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/mapping-to-non-otlp.md?plain=1#L44
      OTEL_LIBRARY_VERSION = 'otel.library.version'

      # The name of the instrumentation scope
      OTEL_SCOPE_NAME = 'otel.scope.name'

      # The version of the instrumentation scope
      OTEL_SCOPE_VERSION = 'otel.scope.version'

      # The value of the [status_code](https://github.com/open-telemetry/opentelemetry-specification/blob/main/semantic_conventions/trace/exporter/exporter.yaml)
      OTEL_STATUS_CODE = 'otel.status_code'
    end
  end
end
