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

          def collect(start_time, end_time)
            @mutex.synchronize do
              metric_data = []
              if @registered_views.empty?
                metric_data << aggregate_metric_data(start_time, end_time)
              else
                @registered_views.each { |view| metric_data << aggregate_metric_data(start_time, end_time, aggregation: view.aggregation) }
              end

              metric_data
            end
          end

          def update(value, attributes)
            if @registered_views.empty?
              @mutex.synchronize { @default_aggregation.update(value, attributes, @data_points) }
            else
              @registered_views.each do |view|
                @mutex.synchronize do
                  attributes ||= {}
                  attributes.merge!(view.attribute_keys)
                  view.aggregation.update(value, attributes, @data_points) if view.valid_aggregation?
                end
              end
            end
          end

          def aggregate_metric_data(start_time, end_time, aggregation: nil)
            aggregator = aggregation || @default_aggregation
            MetricData.new(
              @name,
              @description,
              @unit,
              @instrument_kind,
              @meter_provider.resource,
              @instrumentation_scope,
              aggregator.collect(start_time, end_time, @data_points),
              aggregator.aggregation_temporality,
              start_time,
              end_time
            )
          end

          def find_registered_view
            return if @meter_provider.nil?

            @meter_provider.registered_views.each { |view| @registered_views << view if view.match_instrument?(self) }
          end

          def to_s
            instrument_info = String.new
            instrument_info << "name=#{@name}"
            instrument_info << " description=#{@description}" if @description
            instrument_info << " unit=#{@unit}" if @unit
            @data_points.map do |attributes, value|
              metric_stream_string = String.new
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
