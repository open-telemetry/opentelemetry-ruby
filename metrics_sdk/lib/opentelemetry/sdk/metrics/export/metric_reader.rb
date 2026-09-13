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
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new(cardinality_limit: aggregation_cardinality_limit)
          end

          # Returns the default aggregation class for the given instrument kind.
          def self.default_aggregation(instrument_kind)
            case instrument_kind
            when :histogram
              OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram
            when :counter, :up_down_counter, :observable_counter, :observable_up_down_counter
              OpenTelemetry::SDK::Metrics::Aggregation::Sum
            when :gauge, :observable_gauge
              OpenTelemetry::SDK::Metrics::Aggregation::LastValue
            else
              OpenTelemetry.logger.warn("Unknown instrument kind: #{instrument_kind}, defaulting to Drop aggregation")
              OpenTelemetry::SDK::Metrics::Aggregation::Drop
            end
          end

          # Returns the default aggregation class for the given instrument kind.
          def default_aggregation(instrument_kind)
            self.class.default_aggregation(instrument_kind)
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
