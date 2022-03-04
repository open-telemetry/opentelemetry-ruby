# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {ObservableUpDownCounter} is the SDK implementation of {OpenTelemetry::Metrics::ObservableUpDownCounter}.
        class ObservableUpDownCounter < OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter
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
