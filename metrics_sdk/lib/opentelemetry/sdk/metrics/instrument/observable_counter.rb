# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {ObservableCounter} is the SDK implementation of {OpenTelemetry::Metrics::ObservableCounter}.
        class ObservableCounter < OpenTelemetry::Metrics::Instrument::ObservableCounter
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
