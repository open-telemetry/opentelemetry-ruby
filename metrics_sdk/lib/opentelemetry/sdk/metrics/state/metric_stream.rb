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
            aggregation,
            exemplar_filter,
            exemplar_reservoir
          )
            @name = name
            @description = description
            @unit = unit
            @instrument_kind = instrument_kind
            @meter_provider = meter_provider
            @instrumentation_scope = instrumentation_scope
            @default_aggregation = aggregation
            @data_points = {}
            @registered_views = {}
            @exemplar_filter = exemplar_filter
            @exemplar_reservoir = exemplar_reservoir

            find_registered_view
            @mutex = Mutex.new
          end

          def collect(start_time, end_time)
            @mutex.synchronize do
              metric_data = []

              # data points are required to export over OTLP
              return metric_data if empty_data_point?

              if @registered_views.empty?
                metric_data << aggregate_metric_data(start_time, end_time)
              else
                @registered_views.each do |view, data_points|
                  metric_data << aggregate_metric_data(start_time, end_time, aggregation: view.aggregation, data_points: data_points)
                end
              end

              metric_data
            end
          end

          def update(value, attributes)
            if @registered_views.empty?
              @mutex.synchronize do
                exemplar_offer(value, attributes)
                @default_aggregation.update(value, attributes, @data_points)
              end
            else
              @registered_views.each do |view, data_points|
                @mutex.synchronize do
                  attributes ||= {}
                  attributes.merge!(view.attribute_keys)
                  if view.valid_aggregation?
                    exemplar_offer(value, attributes, view: view)
                    view.aggregation.update(value, attributes, data_points)
                  end
                end
              end
            end
          end

          def aggregate_metric_data(start_time, end_time, aggregation: nil, data_points: nil)
            aggregator = aggregation || @default_aggregation
            is_monotonic = aggregator.respond_to?(:monotonic?) ? aggregator.monotonic? : nil
            aggregation_temporality = aggregator.respond_to?(:aggregation_temporality) ? aggregator.aggregation_temporality : nil
            data_point = data_points || @data_points

            MetricData.new(
              @name,
              @description,
              @unit,
              @instrument_kind,
              @meter_provider.resource,
              @instrumentation_scope,
              aggregator.collect(start_time, end_time, data_point),
              aggregation_temporality,
              start_time,
              end_time,
              is_monotonic
            )
          end

          def find_registered_view
            return if @meter_provider.nil?

            @meter_provider.registered_views.each { |view| @registered_views[view] = {} if view.match_instrument?(self) }
          end

          def empty_data_point?
            if @registered_views.empty?
              @data_points.empty?
            else
              @registered_views.each_value do |data_points|
                return false unless data_points.empty?
              end
            end
          end

          # when view exist, the view should have its own aggregation, which mean has its own reservior
          def exemplar_offer(value, attributes, view: nil)
            context = OpenTelemetry::Context.current
            time = OpenTelemetry::Common::Utilities.time_in_nanoseconds
            return unless @exemplar_filter&.should_sample?(value, time, attributes, context)

            if view
              puts "view.aggregation.exemplar_reservoir: #{view.aggregation.exemplar_reservoir.inspect}"
              view.aggregation.exemplar_reservoir&.offer(value: value, timestamp: time, attributes: attributes, context: context)
            else
              @exemplar_reservoir&.offer(value: value, timestamp: time, attributes: attributes, context: context)
            end
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
