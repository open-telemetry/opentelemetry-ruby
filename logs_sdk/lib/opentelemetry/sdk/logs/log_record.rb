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
                      :severity_text,
                      :severity_number,
                      :body,
                      :attributes,
                      :trace_id,
                      :span_id,
                      :trace_flags,
                      :resource,
                      :instrumentation_scope

        # Creates a new {LogRecord}.
        #
        # @param [optional Time] timestamp Time when the event occurred.
        # @param [optional Time] observed_timestamp Time when the event
        #   was observed by the collection system. If nil, will first attempt
        #   to set to `timestamp`. If `timestamp` is nil, will set to Time.now.
        # @param [optional OpenTelemetry::Trace::SpanContext] span_context The
        #   OpenTelemetry::Trace::SpanContext to associate with the LogRecord.
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
        # @param [optional String] trace_id The trace ID associated with the
        #   current context.
        # @param [optional String] span_id The span ID associated with the
        #   current context.
        # @param [optional OpenTelemetry::Trace::TraceFlags] trace_flags The
        #   trace flags associated with the current context.
        # @param [optional OpenTelemetry::SDK::Resources::Resource] recource The
        #   source of the log, desrived from the LoggerProvider.
        # @param [optional OpenTelemetry::SDK::InstrumentationScope] instrumentation_scope
        #   The instrumentation scope, derived from the emitting Logger
        #
        #
        # @return [LogRecord]
        def initialize(
          timestamp: nil,
          observed_timestamp: nil,
          severity_text: nil,
          severity_number: nil,
          body: nil,
          attributes: nil,
          trace_id: nil,
          span_id: nil,
          trace_flags: nil,
          resource: nil,
          instrumentation_scope: nil
        )
          @timestamp = timestamp
          @observed_timestamp = observed_timestamp || timestamp || Time.now
          @severity_text = severity_text
          @severity_number = severity_number
          @body = body
          @attributes = attributes.nil? ? nil : Hash[attributes] # We need a mutable copy of attributes
          @trace_id = trace_id
          @span_id = span_id
          @trace_flags = trace_flags
          @resource = resource
          @instrumentation_scope = instrumentation_scope
          @total_recorded_attributes = @attributes&.size || 0
        end

        def to_log_record_data
          LogRecordData.new(
            to_integer_nanoseconds(@timestamp),
            to_integer_nanoseconds(@observed_timestamp),
            @severity_text,
            @severity_number,
            @body,
            @attributes,
            @trace_id,
            @span_id,
            @trace_flags,
            @resource,
            @instrumentation_scope,
            @total_recorded_attributes
          )
        end

        private

        def to_integer_nanoseconds(timestamp)
          return unless timestamp.is_a?(Time)

          (timestamp.to_r * 10**9).to_i
        end
      end
    end
  end
end
