# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # @api private
  module Internal
    @meter_provider = ProxyMeterProvider.new
    @meter_provider_mutex = Mutex.new

    class << self
      # Registers the process-wide meter provider that instrumentation reads
      # from. The public +OpenTelemetry.meter_provider+ accessor, defined in
      # +opentelemetry/metrics/global+, delegates here.
      #
      # @param [MeterProvider] provider A meter provider to register as the
      #   global instance.
      def meter_provider=(provider)
        @meter_provider_mutex.synchronize do
          if @meter_provider.instance_of?(ProxyMeterProvider)
            OpenTelemetry.logger.debug("Upgrading default proxy meter provider to #{provider.class}")
            @meter_provider.delegate = provider
          end
          @meter_provider = provider
        end
      end

      # @return [Object, Metrics::MeterProvider] registered meter provider or a
      #   default no-op implementation of the meter provider.
      def meter_provider
        @meter_provider_mutex.synchronize { @meter_provider }
      end
    end
  end
end
