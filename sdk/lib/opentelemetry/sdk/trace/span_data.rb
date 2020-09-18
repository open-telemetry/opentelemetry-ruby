# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Trace module contains the OpenTelemetry tracing reference
    # implementation.
    module Trace
      # SpanData is a Struct containing {Span} data for export.
      SpanData = Struct.new(:name,
                            :kind,
                            :status,
                            :parent_span_id,
                            :total_recorded_attributes,
                            :total_recorded_events,
                            :total_recorded_links,
                            :start_timestamp,
                            :end_timestamp,
                            :attributes,
                            :links,
                            :events,
                            :resource,
                            :instrumentation_library,
                            :span_id,
                            :trace_id,
                            :trace_flags,
                            :tracestate) do
                              # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) span ID.
                              #
                              # @return [String] A 16-hex-character lowercase string.
                              def hex_span_id
                                span_id.unpack1('H*')
                              end

                              # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) trace ID.
                              #
                              # @return [String] A 32-hex-character lowercase string.
                              def hex_trace_id
                                trace_id.unpack1('H*')
                              end
                            end
    end
  end
end
