# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      module Attributes
        # A count of failed exports of spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests
        OTEL_OTLP_EXPORTER_FAILURE = 'otel.otlp_exporter.failure'

        # Compressed size of the message in bytes
        OTEL_OTLP_EXPORTER_MESSAGE_COMPRESSED_SIZE = 'otel.otlp_exporter.message.compressed_size'

        # Uncompressed size of the message in bytes
        OTEL_OTLP_EXPORTER_MESSAGE_UNCOMPRESSED_SIZE = 'otel.otlp_exporter.message.uncompressed_size'

        # Identififes the time it took to send the Spans over HTTP
        OTEL_OTLP_EXPORTER_REQUEST_DURATION = 'otel.otlp_exporter.request_duration'
      end
    end
  end
end
