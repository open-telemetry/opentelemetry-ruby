# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {AsynchronousInstrument} contains the common functionality shared across
        # the asynchronous instruments SDK instruments.
        class AsynchronousInstrument
          def initialize(name, unit, description, callback, instrumentation_scope, meter_provider)
            @name = name
            @unit = unit
            @description = description
            @instrumentation_scope = instrumentation_scope
            @meter_provider = meter_provider
            @metric_streams = []
            @callbacks = []

            register_callback(callback)
            meter_provider.register_asynchronous_instrument(self)
          end

          # @api private
          def register_with_new_metric_store(metric_store, aggregation: default_aggregation)
            ms = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
              @name,
              @description,
              @unit,
              instrument_kind,
              @meter_provider,
              @instrumentation_scope,
              aggregation,
              @callbacks
            )
            @metric_streams << ms
            metric_store.add_metric_stream(ms)
          end

          # For multiple callbacks in single instrument
          def register_callback(callback)
            if callback.instance_of?(Proc)
              @callbacks << callback  # since @callbacks pass to ms, so no need to add it again
            else
              OpenTelemetry.logger.warn "Only accept single Proc for registering callback (given callback #{callback.class}"
            end
          end

          # For callback functions registered after an asynchronous instrument is created,
          def unregister(callback)
            @callbacks.delete(callback)
          end

          private

          # update the observed value (after calling observe)
          # invoke callback will execute callback and export metric_data that is observed
          def update(timeout, attributes)
            @metric_streams.each { |ms| ms.invoke_callback(timeout, attributes) }
          end
        end
      end
    end
  end
end
