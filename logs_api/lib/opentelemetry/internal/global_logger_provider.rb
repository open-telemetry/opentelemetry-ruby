# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # @api private
  module Internal
    @logger_provider = ProxyLoggerProvider.new
    @logger_provider_mutex = Mutex.new

    class << self
      # Registers the process-wide logger provider that instrumentation reads
      # from. The public +OpenTelemetry.logger_provider+ accessor, defined in
      # +opentelemetry/logs/global+, delegates here.
      #
      # @param [LoggerProvider] provider A logger provider to register as the
      #   global instance.
      def logger_provider=(provider)
        @logger_provider_mutex.synchronize do
          if @logger_provider.instance_of?(ProxyLoggerProvider)
            OpenTelemetry.logger.debug("Upgrading default proxy logger provider to #{provider.class}")
            @logger_provider.delegate = provider
          end
          @logger_provider = provider
        end
      end

      # @return [Object, Logs::LoggerProvider] registered logger provider or a
      #   default no-op implementation of the logger provider.
      def logger_provider
        @logger_provider_mutex.synchronize { @logger_provider }
      end
    end
  end
end
