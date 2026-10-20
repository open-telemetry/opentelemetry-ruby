# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyLogger} is an implementation of {OpenTelemetry::Logs::Logger}. It is returned from
    # the ProxyLoggerProvider until a delegate logger provider is installed. After the delegate
    # logger provider is installed, the ProxyLogger will delegate to the corresponding "real"
    # logger.
    class ProxyLogger < Logs::Logger
      attr_writer :delegate

      # Returns a new {ProxyLogger} instance.
      #
      # @return [ProxyLogger]
      def initialize
        @delegate = nil
      end

      # Emits a {LogRecord} through the delegate logger, or discards it while
      # no delegate is installed. See {OpenTelemetry::Logs::Logger#on_emit}.
      def on_emit(
        timestamp: nil,
        observed_timestamp: nil,
        severity_number: nil,
        severity_text: nil,
        body: nil,
        trace_id: nil,
        span_id: nil,
        trace_flags: nil,
        attributes: nil,
        event_name: nil,
        context: nil
      )
        unless @delegate.nil?
          return @delegate.on_emit(
            timestamp: timestamp,
            observed_timestamp: observed_timestamp,
            severity_number: severity_number,
            severity_text: severity_text,
            body: body,
            trace_id: trace_id,
            span_id: span_id,
            trace_flags: trace_flags,
            attributes: attributes,
            event_name: event_name,
            context: context
          )
        end

        super
      end
    end
  end
end
