# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {ObservableGauge} is the SDK implementation of {OpenTelemetry::Metrics::ObservableGauge}.
        class ObservableGauge < OpenTelemetry::Metrics::Instrument::ObservableGauge
          attr_reader :name, :unit, :description

          def initialize(name, unit, description, callback, meter)
            @name = name
            @unit = unit
            @description = description
            @callback = callback
            @meter = meter
          end
        end
      end
    end
  end
end
