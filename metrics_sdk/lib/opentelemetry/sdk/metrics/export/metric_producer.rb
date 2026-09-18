# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # MetricProducer defines the interface that bridges to third-party metric
        # sources must implement, so they can be plugged into a {MetricReader} as
        # an additional source of aggregated metric data.
        class MetricProducer
          # Result of producing a batch of metrics.
          class Result
            attr_reader :metrics, :status, :errors

            # Returns a result containing metrics, status, and errors.
            def initialize(metrics:, status:, errors:)
              @metrics = metrics
              @status = status
              @errors = errors
            end
          end

          attr_reader :aggregation_temporality

          # @param [Symbol, Aggregation::AggregationTemporality] aggregation_temporality
          #   The temporality of metrics produced by this source.
          def initialize(aggregation_temporality:)
            @aggregation_temporality = resolve_temporality(aggregation_temporality)
          end

          # Produces a batch of metrics for a {MetricReader}.
          #
          # @param [OpenTelemetry::SDK::Resources::Resource] resource The resource
          #   to associate with the produced metrics.
          # @param [optional MetricFilter] metric_filter The filter to apply while
          #   producing metrics.
          # @return [Result] produced metrics and operation status.
          def produce(resource:, metric_filter: nil)
            raise NotImplementedError, "#{self.class} must implement #produce"
          end

          private

          def resolve_temporality(value)
            value = value.temporality if value.is_a?(Aggregation::AggregationTemporality)
            return value if %i[delta cumulative].include?(value)

            raise ArgumentError, 'aggregation_temporality must be :delta or :cumulative'
          end
        end
      end
    end
  end
end
