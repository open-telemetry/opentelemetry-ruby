# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # The SDK implementation of OpenTelemetry::Logs::Logger
      class Logger < OpenTelemetry::Logs::Logger
        attr_reader :instrumentation_scope, :logger_provider

        # @api private
        #
        # Returns a new {OpenTelemetry::SDK::Logs::Logger} instance. This should
        # not be called directly. New loggers should be created using
        # {LoggerProvider#logger}.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [LoggerProvider] logger_provider The {LoggerProvider} that
        #   initialized the logger
        #
        # @return [OpenTelemetry::SDK::Logs::Logger]
        def initialize(name, version, logger_provider)
          @instrumentation_scope = InstrumentationScope.new(name, version)
          @logger_provider = logger_provider
        end

        def resource
          logger_provider.resource
        end

        # Emit a {LogRecord} to the processing pipeline.
        #
        # @param timestamp [optional Float, Time] Time in nanoseconds since Unix
        #   epoch when the event occurred measured by the origin clock, i.e. the
        #   time at the source.
        # @param observed_timestamp [optional Float, Time] Time in nanoseconds
        #   since Unix epoch when the event was observed by the collection system.
        #   Intended default: Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
        # @param [optional OpenTelemetry::Trace::SpanContext] span_context The
        #   OpenTelemetry::Trace::SpanContext to associate with the
        #   {LogRecord}.
        # @param severity_number [optional Integer] Numerical value of the
        #   severity. Smaller numerical values correspond to less severe events
        #   (such as debug events), larger numerical values correspond to more
        #   severe events (such as errors and critical events).
        # @param severity_text [optional String] Original string representation of
        #   the severity as it is known at the source. Also known as log level.
        # @param body [optional String, Numeric, Boolean, Array<String, Numeric,
        #   Boolean>, Hash{String => String, Numeric, Boolean, Array<String,
        #   Numeric, Boolean>}] A value containing the body of the log record.
        # @param attributes [optional Hash{String => String, Numeric, Boolean,
        #   Array<String, Numeric, Boolean>}] Additional information about the
        #   event.
        #
        # @api public
        def on_emit(timestamp: nil,
                 observed_timestamp: nil,
                 span_context: nil, # or should this just be context? like in the API?
                 severity_number: nil,
                 severity_text: nil,
                 body: nil,
                 attributes: nil)
          log_record = LogRecord.new(timestamp: timestamp,
                                     observed_timestamp: observed_timestamp,
                                     span_context: span_context ||= OpenTelemetry::Trace.current_span.context,
                                     severity_text: severity_text,
                                     severity_number: severity_number,
                                     body: body,
                                     attributes: attributes,
                                     logger: self)

          logger_provider.instance_variable_get(:@log_record_processors).each do |processor|
            processor.on_emit(log_record, span_context)
          end
        end
      end
    end
  end
end
