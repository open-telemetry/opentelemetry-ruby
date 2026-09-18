# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # MetricFilter filters metric streams and their data points.
        class MetricFilter
          # MetricFilterResult represents the possible outcomes of applying a metric filter.
          class MetricFilterResult
            ACCEPT = :accept
            DROP = :drop
            ACCEPT_PARTIAL = :accept_partial
          end

          # Tests whether a metric stream should be accepted.
          def test_metric(instrumentation_scope:, name:, kind:, unit:)
            raise NotImplementedError, "#{self.class} must implement #test_metric"
          end

          # Tests whether a data point's attributes should be accepted.
          def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
            raise NotImplementedError, "#{self.class} must implement #test_attributes"
          end

          # Applies this filter to a batch of metric data.
          def filter(metrics)
            metrics.filter_map { |metric| filter_metric(metric) }
          end

          private

          def filter_metric(metric)
            arguments = metric_arguments(metric)
            case test_metric(**arguments)
            when MetricFilterResult::ACCEPT
              metric
            when MetricFilterResult::DROP
              nil
            when MetricFilterResult::ACCEPT_PARTIAL
              filter_data_points(metric, arguments)
            else
              raise ArgumentError, 'test_metric must return ACCEPT, DROP, or ACCEPT_PARTIAL'
            end
          end

          def filter_data_points(metric, arguments)
            data_points = metric.data_points.select do |data_point|
              case test_attributes(**arguments, attributes: data_point.attributes)
              when MetricFilterResult::ACCEPT
                true
              when MetricFilterResult::DROP
                false
              else
                raise ArgumentError, 'test_attributes must return ACCEPT or DROP'
              end
            end
            return if data_points.empty?

            metric.dup.tap { |filtered_metric| filtered_metric.data_points = data_points }
          end

          def metric_arguments(metric)
            {
              instrumentation_scope: metric.instrumentation_scope,
              name: metric.name,
              kind: metric.instrument_kind,
              unit: metric.unit
            }
          end
        end
      end
    end
  end
end
