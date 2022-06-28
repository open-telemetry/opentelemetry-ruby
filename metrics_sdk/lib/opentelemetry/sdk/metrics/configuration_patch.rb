# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      # The ConfiguratorPatch implements a hook to configure the metrics
      # portion of the SDK.
      module ConfiguratorPatch
        private

        # The metrics_configuration_hook method is where we define the setup process
        # for metrics SDK.
        def metrics_configuration_hook
          OpenTelemetry.meter_provider = Metrics::MeterProvider.new(resource: @resource)
        end
      end
    end
  end
end

OpenTelemetry::SDK::Configurator.prepend(OpenTelemetry::SDK::Metrics::ConfiguratorPatch)
