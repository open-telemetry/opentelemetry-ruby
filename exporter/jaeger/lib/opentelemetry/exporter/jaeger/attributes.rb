# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Jaeger
      module Attributes
        # Identifies Jaeger failed trace exports
        OTEL_JAEGER_EXPORTER_FAILURE = 'otel.jaeger_exporter.failure'

        # Identifies the time it took to flush Spans to Jaeger
        OTEL_JAEGER_EXPORTER_REQUEST_DURATION = 'otel.jaeger_exporter.request_duration'
      end
    end
  end
end
