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
        # The AsynchronousMetricStream class provides SDK internal functionality that is not a part of the
        # public API. It extends MetricStream to support asynchronous instruments.
        class AsynchronousMetricStream < MetricStream
          DEFAULT_TIMEOUT = 30

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
            # Call parent constructor with common parameters
            super(name, description, unit, instrument_kind, meter_provider, instrumentation_scope, aggregation)

            # Initialize asynchronous-specific attributes
            @callback = callback
            @start_time = now_in_nano
            @timeout = timeout
            @attributes = attributes
          end

          # When collect, if there are asynchronous SDK Instruments involved, their callback functions will be triggered.
          # Related spec: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#collect
          # invoke_callback will update the data_points in aggregation
          def collect(start_time, end_time)
            invoke_callback(@timeout, @attributes)

            # Call parent collect method for the core collection logic
            super(start_time, end_time)
          end

          def invoke_callback(timeout, attributes)
            if @registered_views.empty?
              @mutex.synchronize do
                @callback.each do |cb|
                  value = safe_guard_callback(cb, timeout: timeout)
                  @default_aggregation.update(value, attributes, @data_points) if value.is_a?(Numeric)
                end
              end
            else
              @registered_views.each do |view|
                @mutex.synchronize do
                  @callback.each do |cb|
                    value = safe_guard_callback(cb, timeout: timeout)
                    next unless value.is_a?(Numeric) # ignore if value is not valid number

                    merged_attributes = attributes || {}
                    merged_attributes.merge!(view.attribute_keys)
                    view.aggregation.update(value, merged_attributes, @data_points) if view.valid_aggregation?
                  end
                end
              end
            end
          end

          def now_in_nano
            (Time.now.to_r * 1_000_000_000).to_i
          end

          private

          def safe_guard_callback(callback, timeout: DEFAULT_TIMEOUT)
            Timeout.timeout(timeout) do
              callback.call
            end
          rescue Timeout::Error => e
            OpenTelemetry.logger.error("Timeout while invoking callback: #{e.message}")
          rescue StandardError => e
            OpenTelemetry.logger.error("Error invoking callback: #{e.message}")
          end
        end
      end
    end
  end
end
