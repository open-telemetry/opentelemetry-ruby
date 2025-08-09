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
        # rubocop:disable Metrics/ClassLength
        class AsynchronousMetricStream
          attr_reader :name, :description, :unit, :instrument_kind, :instrumentation_scope, :data_points

          def initialize(
            name,
            description,
            unit,
            instrument_kind,
            meter_provider,
            instrumentation_scope,
            aggregation,
            callback,
            timeout,
            attributes
          )
            @name = name
            @description = description
            @unit = unit
            @instrument_kind = instrument_kind
            @meter_provider = meter_provider
            @instrumentation_scope = instrumentation_scope
            @default_aggregation = aggregation
            @callback = callback
            @start_time = now_in_nano
            @timeout = timeout
            @attributes = attributes
            @data_points = {}
            @registered_views = []

            find_registered_view
            @mutex = Mutex.new
          end

          # When collect, if there are asynchronous SDK Instruments involved, their callback functions will be triggered.
          # Related spec: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#collect
          # invoke_callback will update the data_points in aggregation
          def collect(start_time, end_time)
            invoke_callback(@timeout, @attributes)

            @mutex.synchronize do
              metric_data = []

              # data points are required to export over OTLP
              return metric_data if @data_points.empty?

              if @registered_views.empty?
                metric_data << aggregate_metric_data(start_time, end_time)
              else
                @registered_views.each { |view| metric_data << aggregate_metric_data(start_time, end_time, aggregation: view.aggregation) }
              end

              metric_data
            end
          end

          def invoke_callback(timeout, attributes)
            if @registered_views.empty?
              @mutex.synchronize do
                Timeout.timeout(timeout || 30) do
                  @callback.each do |cb|
                    value = cb.call
                    @default_aggregation.update(value, attributes, @data_points)
                  end
                end
              end
            else
              @registered_views.each do |view|
                @mutex.synchronize do
                  Timeout.timeout(timeout || 30) do
                    @callback.each do |cb|
                      value = cb.call
                      merged_attributes = attributes || {}
                      merged_attributes.merge!(view.attribute_keys)
                      view.aggregation.update(value, merged_attributes, @data_points) if view.valid_aggregation?
                    end
                  end
                end
              end
            end
          end

          def aggregate_metric_data(start_time, end_time, aggregation: nil)
            aggregator = aggregation || @default_aggregation
            is_monotonic = aggregator.respond_to?(:monotonic?) ? aggregator.monotonic? : nil

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
              end_time,
              is_monotonic
            )
          end

          def find_registered_view
            return if @meter_provider.nil?

            @meter_provider.registered_views.each { |view| @registered_views << view if view.match_instrument?(self) }
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

          def now_in_nano
            (Time.now.to_r * 1_000_000_000).to_i
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
