# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Logs
    # No-op implementation of logger.
    class Logger
      # rubocop:disable Style/EmptyMethod

      # Emit a {LogRecord} to the processing pipeline.
      #
      # @param timestamp [optional Float, Time] Time in nanoseconds since Unix
      #   epoch when the event occurred measured by the origin clock, i.e. the
      #   time at the source.
      # @param observed_timestamp [optional Float, Time] Time in nanoseconds
      #   since Unix epoch when the event was observed by the collection system.
      #   Intended default: Process.clock_gettime(Process::CLOCK_REALTIME)
      # @param context [optional Context] The Context to associate with the
      #   LogRecord. Intended default: OpenTelemetry::Context.current
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
      def emit(
        timestamp: nil,
        observed_timestamp: nil,
        context: nil,
        severity_number: nil,
        severity_text: nil,
        body: nil,
        attributes: nil
      )
      end
      # rubocop:enable Style/EmptyMethod
    end
  end
end
