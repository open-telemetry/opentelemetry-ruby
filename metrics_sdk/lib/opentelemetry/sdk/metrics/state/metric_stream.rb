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
          attr_reader :name, :description, :unit, :instrument_kind, :instrumentation_scope

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
            @registered_views = []

            find_registered_view
            @mutex = Mutex.new
          end

          def collect(start_time, end_time)
            @mutex.synchronize do
              metric_data = []

              if @registered_views.empty?
                metric_data << aggregate_metric_data(start_time, end_time)
              else
                @registered_views.each { |view| metric_data << aggregate_metric_data(start_time, end_time, aggregation: view.aggregation) }
              end

              # reject metric_data with empty data_points
              # data points are required to export over OTLP
              metric_data.reject! { |metric| metric.data_points.empty? }
              return [] if metric_data.empty?

              metric_data
            end
          end

          def update(value, attributes)
            if @registered_views.empty?
              @mutex.synchronize { @default_aggregation.update(value, attributes) }
            else
              @registered_views.each do |view|
                @mutex.synchronize do
                  attributes ||= {}
                  attributes.merge!(view.attribute_keys)
                  view.aggregation.update(value, attributes) if view.valid_aggregation?
                end
              end
            end
          end

          def aggregate_metric_data(start_time, end_time, aggregation: nil)
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
              aggregator.collect(start_time, end_time),
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

          def to_s
            instrument_info = []
            instrument_info << "name=#{@name}"
            instrument_info << " description=#{@description}" if @description
            instrument_info << " unit=#{@unit}" if @unit
            instrument_info << " instrument_kind=#{@instrument_kind}" if @instrument_kind
            instrument_info << " instrumentation_scope=#{@instrumentation_scope.name}@#{@instrumentation_scope.version}" if @instrumentation_scope
            instrument_info << " default_aggregation=#{@default_aggregation.class}" if @default_aggregation
            instrument_info << " registered_views=#{@registered_views.map { |view| "name=#{view.name}, aggregation=#{view.aggregation.class}" }.join('; ')}" unless @registered_views.empty?
            instrument_info.join('.')
          end
        end
      end
    end
  end
end
