# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Zipkin
      module Attributes
        # A count of failures when exporting Spans to Zipkin
        OTEL_ZIPKIN_EXPORTER_FAILURE = 'otel.zipkin_exporter.failure'

        # Identifies the time it took to flush Spans to Zipkin
        OTEL_ZIPKIN_EXPORTER_REQUEST_DURATION = 'otel.zipkin_exporter.request_duration'
      end
    end
  end
end
