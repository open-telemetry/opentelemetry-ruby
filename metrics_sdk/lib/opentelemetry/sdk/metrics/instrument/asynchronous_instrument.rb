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

          def register_callback(callback)
            callbacks = [callback] unless callback.instance_of? Array

            callbacks.each do |cb|
              if cb.instance_of? Proc
                @callbacks << cb
              else
                OpenTelemetry.logger.warn "The callback registeration failed for instrument #{@name}"
              end
            end
            @meter_provider.register_callback(self, @callbacks) # meter_provider should register list of callback
          end

          def remove_callback(callback)
            orig_callback_size = @callbacks.size
            callbacks = [callback] unless callback.instance_of? Array

            callbacks.each { |cb| @callback.delete(cb) }
            @meter_provider.register_callback(self, @callbacks) if @callback.size != orig_callback_size
          end

          private

          def update(timeout, attributes)
            @metric_streams.each { |ms| ms.invoke_callback(timeout, attributes) }
          end
        end
      end
    end
  end
end
