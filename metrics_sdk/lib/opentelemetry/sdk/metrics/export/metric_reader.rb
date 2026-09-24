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
          # The default aggregation for each instrument kind, as defined by the
          # metrics SDK specification.
          # https://opentelemetry.io/docs/specs/otel/metrics/sdk/#default-aggregation
          DEFAULT_AGGREGATION = {
            counter: OpenTelemetry::SDK::Metrics::Aggregation::Sum,
            up_down_counter: OpenTelemetry::SDK::Metrics::Aggregation::Sum,
            observable_counter: OpenTelemetry::SDK::Metrics::Aggregation::Sum,
            observable_up_down_counter: OpenTelemetry::SDK::Metrics::Aggregation::Sum,
            gauge: OpenTelemetry::SDK::Metrics::Aggregation::LastValue,
            observable_gauge: OpenTelemetry::SDK::Metrics::Aggregation::LastValue,
            histogram: OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram
          }.freeze

          attr_reader :metric_store

          # @return [Hash{Symbol => Class}] the aggregation class to use for each
          #   instrument kind, resolved once at construction.
          attr_reader :default_aggregation

          # @param [optional Integer] aggregation_cardinality_limit the maximum number of
          #   data points to keep per metric stream.
          # @param [optional Hash{Symbol => Class}] default_aggregation aggregation classes
          #   keyed by instrument kind, applied on top of {DEFAULT_AGGREGATION}.
          def initialize(aggregation_cardinality_limit: nil, default_aggregation: nil)
            @default_aggregation = DEFAULT_AGGREGATION.merge(default_aggregation || {})
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new(cardinality_limit: aggregation_cardinality_limit)
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
