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
      # Returns a new {ProxyLogger} instance.
      #
      # @return [ProxyLogger]
      def initialize
        super
        @mutex = Mutex.new
        @delegate = nil
      end

      # Set the delegate Logger. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [Logger] logger The Logger to delegate to
      def delegate=(logger)
        @mutex.synchronize do
          if @delegate.nil?
            @delegate = logger
          else
            OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyLogger ignored.'
          end
        end
      end

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
        context: nil
      )
        unless @delegate.nil?
          return @delegate.on_emit(
            timestamp: nil,
            observed_timestamp: nil,
            severity_number: nil,
            severity_text: nil,
            body: nil,
            trace_id: nil,
            span_id: nil,
            trace_flags: nil,
            attributes: nil,
            context: nil
          )
        end

        super
      end
    end
  end
end
