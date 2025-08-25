# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module State
        # @api private
        #
        # The MetricStream class provides SDK internal functionality that is not a part of the
        # public API.
        class MetricStream
          attr_reader :name, :description, :unit, :instrument_kind, :instrumentation_scope, :data_points
          attr_writer :cardinality_limit

          DEFAULT_CARDINALITY_LIMIT = 2000

          def initialize(
            name,
            description,
            unit,
            instrument_kind,
            meter_provider,
            instrumentation_scope,
            aggregation
          )
            @name = name
            @description = description
            @unit = unit
            @instrument_kind = instrument_kind
            @meter_provider = meter_provider
            @instrumentation_scope = instrumentation_scope
            @default_aggregation = aggregation
            @data_points = {}
            @registered_views = []

            find_registered_view
            @mutex = Mutex.new
          end

          # this cardinality_limit is from exporter.new(cardinality_limit: cardinality_limit)
          #                                -> metric_reader.collect(...cardinality_limit)
          #                                -> metric_store.collect(...cardinality_limit)
          #                                -> metric_stream.collect(...cardinality_limit)
          def collect(start_time, end_time)
            @mutex.synchronize do
              metric_data = []

              # data points are required to export over OTLP
              return metric_data if @data_points.empty?

              if @registered_views.empty?
                resolved_cardinality_limit = @cardinality_limit || DEFAULT_CARDINALITY_LIMIT
                metric_data << aggregate_metric_data(start_time,
                                                     end_time,
                                                     resolved_cardinality_limit)
              else
                @registered_views.each do |view|
                  resolved_cardinality_limit = resolve_cardinality_limit(view)
                  metric_data << aggregate_metric_data(start_time,
                                                       end_time,
                                                       resolved_cardinality_limit,
                                                       aggregation: view.aggregation)
                end
              end

              metric_data
            end
          end

          # view has the cardinality, pass to aggregation update
          # to determine if aggregation have the cardinality
          # if the aggregation does not have the cardinality, then it will be default 2000
          # it better to move overflowed data_points during update because if do it in collect,
          # then we need to sort the entire data_points (~ 2000) based on time, which is time-consuming
          def update(value, attributes)
            if @registered_views.empty?
              resolved_cardinality_limit = @cardinality_limit || DEFAULT_CARDINALITY_LIMIT

              @mutex.synchronize { @default_aggregation.update(value, attributes, @data_points, resolved_cardinality_limit) }
            else
              @registered_views.each do |view|
                resolved_cardinality_limit = resolve_cardinality_limit(view)
                @mutex.synchronize do
                  attributes ||= {}
                  attributes.merge!(view.attribute_keys)
                  view.aggregation.update(value, attributes, @data_points, resolved_cardinality_limit) if view.valid_aggregation?
                end
              end
            end
          end

          def aggregate_metric_data(start_time, end_time, cardinality_limit, aggregation: nil)
            aggregator = aggregation || @default_aggregation
            is_monotonic = aggregator.respond_to?(:monotonic?) ? aggregator.monotonic? : nil
            aggregation_temporality = aggregator.respond_to?(:aggregation_temporality) ? aggregator.aggregation_temporality : nil

            MetricData.new(
              @name,
              @description,
              @unit,
              @instrument_kind,
              @meter_provider.resource,
              @instrumentation_scope,
              aggregator.collect(start_time, end_time, @data_points, cardinality_limit),
              aggregation_temporality,
              start_time,
              end_time,
              is_monotonic
            )
          end

          def find_registered_view
            return if @meter_provider.nil?

            @meter_provider.registered_views.each { |view| @registered_views << view if view.match_instrument?(self) }
          end

          def resolve_cardinality_limit(view)
            view.aggregation_cardinality_limit || @cardinality_limit || DEFAULT_CARDINALITY_LIMIT
          end

          def to_s
            instrument_info = +''
            instrument_info << "name=#{@name}"
            instrument_info << " description=#{@description}" if @description
            instrument_info << " unit=#{@unit}" if @unit
            @data_points.map do |attributes, value|
              metric_stream_string = +''
              metric_stream_string << instrument_info
              metric_stream_string << " attributes=#{attributes}" if attributes
              metric_stream_string << " #{value}"
              metric_stream_string
            end.join("\n")
          end
        end
      end
    end
  end
end
