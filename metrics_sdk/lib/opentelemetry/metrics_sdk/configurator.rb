# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module MetricsSDK
    # The configurator provides defaults and facilitates configuring the
    # SDK for use.
    class Configurator

      # @api private
      # The configure method is where we define the setup process. This allows
      # us to make certain guarantees about which systems and globals are setup
      # at each stage.
      def configure
        OpenTelemetry.meter_provider = Metrics::MeterProvider.new
      end
    end
  end
end
