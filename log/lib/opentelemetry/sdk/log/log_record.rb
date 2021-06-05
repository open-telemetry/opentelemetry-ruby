# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      # A LogRecord is a single log event.
      class LogRecord
        attr_reader \
          :timestamp,
          :trace_id,
          :span_id,
          :trace_flags,
          :severity_text,
          :severity_number,
          :name,
          :body,
          :attributes

        def initialize(
          timestamp:,
          trace_id: nil,
          span_id: nil,
          trace_flags: nil,
          severity_text: nil,
          severity_number: nil,
          name: nil,
          body: nil,
          attributes: nil
        )
          @timestamp = timestamp
          @trace_id = trace_id
          @span_id = span_id
          @trace_flags = trace_flags
          @severity_text = severity_text
          @severity_number = severity_number
          @name = name
          @body = body
          @attributes = attributes
        end
      end
    end
  end
end
