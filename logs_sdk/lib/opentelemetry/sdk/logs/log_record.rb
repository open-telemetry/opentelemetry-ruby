# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # Implementation of OpenTelemetry::Logs::LogRecord that records log events.
      class LogRecord < OpenTelemetry::Logs::LogRecord
        attr_accessor :timestamp,
                      :observed_timestamp,
                      :span_context,
                      :severity_text,
                      :severity_number,
                      :body,
                      :resource,
                      :instrumentation_scope,
                      :attributes

        # Creates a new {LogRecord}.
        #
        # @param [optional Float, Time] timestamp Time when the event occurred.
        # @param [optional Float, Time] observed_timestamp Time when the event
        #   was observed by the collection system. If nil, will first attempt
        #   to set to `timestamp`. If `timestamp` is nil, will set to
        #   `Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)`.
        # @param [optional OpenTelemetry::Trace::SpanContext] span_context The
        #   OpenTelemetry::Trace::SpanContext to associate with the
        #   {LogRecord}.
        # @param [optional String] severity_text The log severity, also known as
        #   log level.
        # @param [optional Integer] severity_number The numerical value of the
        #   log severity.
        # @param [optional String, Numeric, Boolean, Array<String, Numeric,
        #   Boolean>, Hash{String => String, Numeric, Boolean, Array<String,
        #   Numeric, Boolean>}] body The body of the {LogRecord}.
        # @param [optional Hash{String => String, Numeric, Boolean,
        #   Array<String, Numeric, Boolean>}] attributes Attributes to associate
        #   with the {LogRecord}.
        # @param [optional OpenTelemetry::SDK::Logs::Logger] logger The logger that
        #   created the {LogRecord}. Used to set `resource` and
        #   `instrumentation_scope`.
        #
        # @return [LogRecord]
        def initialize(
          timestamp: nil,
          observed_timestamp: nil,
          span_context: nil,
          severity_text: nil,
          severity_number: nil,
          body: nil,
          attributes: nil,
          logger: nil
        )
          @timestamp = timestamp
          @observed_timestamp = observed_timestamp || timestamp || Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
          @span_context = span_context
          @severity_text = severity_text
          @severity_number = severity_number
          @body = body
          @resource = logger&.resource
          @instrumentation_scope = logger&.instrumentation_scope
          @attributes = attributes.nil? ? nil : Hash[attributes] # We need a mutable copy of attributes
          @total_recorded_attributes = @attributes&.size || 0
        end

        def to_log_record_data
          LogRecordData.new(
            @timestamp,
            @observed_timestamp,
            @span_context&.trace_id,
            @span_context&.span_id,
            @span_context&.trace_flags,
            @severity_text,
            @severity_number,
            @body,
            @resource,
            @instrumentation_scope,
            @attributes,
            @total_recorded_attributes
          )
        end
      end
    end
  end
end
