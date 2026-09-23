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
            @stopped = false
          end

          # Collects and returns the current metrics from the metric store.
          # Returns an empty Array if the reader has been shut down.
          def collect
            if @stopped
              OpenTelemetry.logger.warn('MetricReader already shutdown, ignoring collect request')
              return []
            end

            @metric_store.collect
          end

          # Marks this reader as stopped so subsequent collections fail.
          # Subclasses that override this method should call super.
          def shutdown(timeout: nil)
            @stopped = true
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
