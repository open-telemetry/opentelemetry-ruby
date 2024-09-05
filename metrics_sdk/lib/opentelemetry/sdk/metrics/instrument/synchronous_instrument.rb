# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {SynchronousInstrument} contains the common functionality shared across
        # the synchronous instruments SDK instruments.
        class SynchronousInstrument
          def initialize(name, unit, description, instrumentation_scope, meter_provider, advice = nil)
            @name = name
            @unit = unit
            @description = description
            @instrumentation_scope = instrumentation_scope
            @meter_provider = meter_provider
            @metric_streams = []

            meter_provider.register_synchronous_instrument(self)
          end

          # @api private
          def register_with_new_metric_store(metric_store, aggregation: default_aggregation)
            ms = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
              @name,
              @description,
              @unit,
              instrument_kind,
              @meter_provider,
              @instrumentation_scope,
              aggregation
            )
            @metric_streams << ms
            metric_store.add_metric_stream(ms)
          end

          private

          def update(value, attributes)
            @metric_streams.each { |ms| ms.update(value, attributes) }
          end
        end
      end
    end
  end
end
