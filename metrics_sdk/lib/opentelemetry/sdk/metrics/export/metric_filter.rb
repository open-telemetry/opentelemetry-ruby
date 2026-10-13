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

          class AttributesFilterResult
            ACCEPT = :accept
            DROP = :drop
          end

          # Point kind assumed for a stream without data points, based on the
          # instrument's default aggregation.
          DEFAULT_POINT_KINDS = {
            counter: :sum,
            up_down_counter: :sum,
            observable_counter: :sum,
            observable_up_down_counter: :sum,
            gauge: :gauge,
            observable_gauge: :gauge,
            histogram: :histogram
          }.freeze

          private_constant :DEFAULT_POINT_KINDS

          # Tests whether a metric stream should be accepted.
          #
          # @param [InstrumentationScope] instrumentation_scope The metric stream instrumentation scope.
          # @param [String] name The name of the metric stream.
          # @param [Symbol] kind The metric stream point kind: :sum, :gauge,
          #   :histogram, or :exponential_histogram.
          # @param [String] unit The metric stream unit.
          # @return [Symbol] One of the {MetricFilterResult} values.
          def test_metric(instrumentation_scope:, name:, kind:, unit:)
            raise NotImplementedError, "#{self.class} must implement #test_metric"
          end

          # Tests whether a data point's attributes should be accepted. Receives
          # the same stream arguments as {#test_metric}, plus the data point's
          # attributes.
          #
          # @return [Symbol] One of the {AttributesFilterResult} values.
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
              when AttributesFilterResult::ACCEPT
                true
              when AttributesFilterResult::DROP
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
              kind: point_kind(metric),
              unit: metric.unit
            }
          end

          # Derives the data model point kind, which differs from the instrument
          # kind when a view changes the stream's aggregation. Number data points
          # come from either a Sum or a LastValue aggregation; only Sum sets
          # is_monotonic.
          def point_kind(metric)
            case metric.data_points.first
            when Aggregation::ExponentialHistogramDataPoint then :exponential_histogram
            when Aggregation::HistogramDataPoint then :histogram
            when Aggregation::NumberDataPoint then metric.is_monotonic.nil? ? :gauge : :sum
            else DEFAULT_POINT_KINDS.fetch(metric.instrument_kind, :sum)
            end
          end
        end
      end
    end
  end
end
