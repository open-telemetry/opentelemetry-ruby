# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # MetricReader provides a minimal example implementation.
        # It is not required to subclass this class to provide an implementation
        # of MetricReader, provided the interface is satisfied.
        class MetricReader
          attr_reader :metric_store

          def initialize(aggregation_cardinality_limit: nil)
            @mutex = Mutex.new
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new(cardinality_limit: aggregation_cardinality_limit)
          end

          # Registers this reader with a MeterProvider.
          def register_meter_provider(meter_provider)
            @mutex.synchronize do
              if @meter_provider && !@meter_provider.equal?(meter_provider)
                raise ArgumentError, 'MetricReader cannot be registered with more than one MeterProvider'
              end

              @meter_provider = meter_provider
            end
          end

          # Collects and returns the current metrics from the metric store.
          def collect
            @metric_store.collect
          end

          # No-op: subclasses should override to release resources.
          def shutdown(timeout: nil)
            Export::SUCCESS
          end

          # No-op: subclasses should override to force an export.
          def force_flush(timeout: nil)
            Export::SUCCESS
          end
        end
      end
    end
  end
end
