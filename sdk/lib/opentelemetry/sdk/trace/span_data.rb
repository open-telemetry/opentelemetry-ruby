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
                            :child_count,
                            :total_recorded_attributes,
                            :total_recorded_events,
                            :total_recorded_links,
                            :start_timestamp,
                            :end_timestamp,
                            :attributes,
                            :links,
                            :events,
                            :library_resource,
                            :instrumentation_library,
                            :span_id,
                            :trace_id,
                            :trace_flags,
                            :tracestate)
    end
  end
end
