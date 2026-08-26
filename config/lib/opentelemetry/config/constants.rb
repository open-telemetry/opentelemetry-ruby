# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'

require_relative 'generated_constants'

module OpenTelemetry
  module Config
    RubySDK = Struct.new(
      :tracer_provider,
      :meter_provider,
      :logger_provider,
      :resource,
      :propagator
    ) do
      # Shuts down every configured provider. No-op providers are skipped.
      #
      # @param timeout [Numeric, nil] the maximum time, in seconds, allowed for
      #   each provider to shut down
      # @return [void]
      def shutdown(timeout: nil)
        [tracer_provider, meter_provider, logger_provider].each do |provider|
          next unless provider.respond_to?(:shutdown)

          provider.shutdown(timeout: timeout)
        rescue StandardError => e
          OpenTelemetry.logger.error("Failed to shut down #{provider.class}: #{e.message}")
        end
        nil
      end
    end

    # Sentinel returned from every no-op path of {Config.create}. {Config.install}
    # compares against this object identity to leave global state untouched.
    NOOP_SDK = RubySDK.new(
      tracer_provider: OpenTelemetry::Trace::TracerProvider.new,
      propagator: OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new
    ).freeze
  end
end
