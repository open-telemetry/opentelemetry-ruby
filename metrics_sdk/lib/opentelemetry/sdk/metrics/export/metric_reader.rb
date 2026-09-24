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

          # Collects and returns the current metrics from the metric store.
          def collect
            @metric_store.collect
          end

          # Collects the current metrics and reports whether the collection
          # succeeded, failed, or timed out.
          #
          # Metrics gathered before a timeout are still returned: collecting has
          # already advanced the metric store, so dropping them would lose data.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [CollectionResult] the collected metrics with a status of
          #   SUCCESS, FAILURE, or TIMEOUT. On FAILURE the metrics are empty.
          def collect_with_result(timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            metrics = collect
            status = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)&.zero? ? Export::TIMEOUT : Export::SUCCESS
            CollectionResult.new(metrics, status)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'Failed to collect metrics.')
            CollectionResult.new([], Export::FAILURE)
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
