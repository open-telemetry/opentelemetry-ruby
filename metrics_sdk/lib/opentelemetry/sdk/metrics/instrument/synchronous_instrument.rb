# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {SynchronousInstrument} contains the common functionality shared across
        # the synchronous instruments SDK instruments.
        class SynchronousInstrument
          NOOP_EXEMPLAR_RESERVOIR = Exemplar::NoopExemplarReservoir.new

          def initialize(name, unit, description, instrumentation_scope, meter_provider, exemplar_filter, exemplar_reservoir)
            @name = name
            @unit = unit
            @description = description
            @instrumentation_scope = instrumentation_scope
            @meter_provider = meter_provider
            @metric_streams = []
            @exemplar_filter = exemplar_filter || meter_provider.exemplar_filter
            @exemplar_reservoir = exemplar_reservoir || NOOP_EXEMPLAR_RESERVOIR

            meter_provider.register_synchronous_instrument(self)
          end

          # @api private
          def register_with_new_metric_store(metric_store, aggregation: default_aggregation)
            ms = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
              @name,
              @description,
              @unit,
              instrument_kind,
              @meter_provider,
              @instrumentation_scope,
              aggregation
            )
            @metric_streams << ms
            metric_store.add_metric_stream(ms)
          end

          private

          def update(value, attributes)
            @metric_streams.each { |ms| ms.update(value, attributes) }
          end

          # Adding the exemplar to reservoir
          # Only record the exemplar if exemplar_filter decide to sample/record it
          def exemplar_offer(value, attributes)
            context = OpenTelemetry::Context.current
            time = (Time.now.to_r * 1_000_000).to_i
            return unless @exemplar_filter.should_sample?(value, time, attributes, context)

            @exemplar_reservoir.offer(value: value, timestamp: time, attributes: attributes, context: context)
          end
        end
      end
    end
  end
end
