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

          # @param [optional Symbol, Aggregation::AggregationTemporality] aggregation_temporality
          #   The temporality of metrics produced by this source.
          def initialize(aggregation_temporality: nil)
            @aggregation_temporality = resolve_temporality(aggregation_temporality)
          end

          # Produces a batch of metrics for a {MetricReader}.
          #
          # @param [OpenTelemetry::SDK::Resources::Resource] resource The resource
          #   to associate with the produced metrics.
          # @param [optional MetricFilter] metric_filter The filter to apply while
          #   producing metrics.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Result] produced metrics and operation status.
          def produce(resource: nil, metric_filter: nil, timeout: nil)
            raise NotImplementedError, "#{self.class} must implement #produce"
          end

          private

          def resolve_temporality(value)
            if value.is_a?(Aggregation::AggregationTemporality)
              value.temporality
            elsif %i[delta cumulative].include?(value)
              value
            else
              # spec doesn't define if temporality is nil, we give delta as default
              OpenTelemetry.logger.warn('Aggregation temporality not specified or invalid, defaulting to delta')
              Aggregation::AggregationTemporality::DELTA
            end
          end
        end
      end
    end
  end
end
