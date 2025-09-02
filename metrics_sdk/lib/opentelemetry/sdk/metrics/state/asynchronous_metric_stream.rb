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

              resolved_cardinality_limit = @cardinality_limit || DEFAULT_CARDINALITY_LIMIT
              @mutex.synchronize do
                Timeout.timeout(timeout || 30) do
                  @callback.each do |cb|
                    value = cb.call
                    @default_aggregation.update(value, attributes, @data_points, resolved_cardinality_limit)
                  end
                end
              end
            else
              @registered_views.each do |view|
                resolved_cardinality_limit = resolve_cardinality_limit(view)

                @mutex.synchronize do
                  Timeout.timeout(timeout || 30) do
                    @callback.each do |cb|
                      value = cb.call
                      merged_attributes = attributes || {}
                      merged_attributes.merge!(view.attribute_keys)
                      view.aggregation.update(value, merged_attributes, @data_points, resolved_cardinality_limit) if view.valid_aggregation?
                    end
                  end
                end
              end
            end
          end

          def now_in_nano
            (Time.now.to_r * 1_000_000_000).to_i
          end
        end
      end
    end
  end
end
