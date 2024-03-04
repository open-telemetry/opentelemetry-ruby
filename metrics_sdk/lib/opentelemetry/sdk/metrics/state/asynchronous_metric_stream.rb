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
            @aggregation = aggregation
            @callback = callback
            @start_time = now_in_nano
            @timeout = timeout
            @attributes = attributes

            @mutex = Mutex.new
          end

          # When collect, if there are asynchronous SDK Instruments involved, their callback functions will be triggered.
          # Related spec: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#collect
          # invoke_callback will update the data_points in aggregation
          def collect(start_time, end_time)
            invoke_callback(@timeout, @attributes)

            @mutex.synchronize do
              MetricData.new(
                @name,
                @description,
                @unit,
                @instrument_kind,
                @meter_provider.resource,
                @instrumentation_scope,
                @aggregation.collect(start_time, end_time),
                @aggregation.aggregation_temporality,
                start_time,
                end_time
              )
            end
          end

          def invoke_callback(timeout, attributes)
            @mutex.synchronize do
              Timeout.timeout(timeout || 30) do
                @callback.each do |cb|
                  value = cb.call
                  @aggregation.update(value, attributes)
                end
              end
            end
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

          def now_in_nano
            (Time.now.to_r * 1_000_000_000).to_i
          end
        end
      end
    end
  end
end
