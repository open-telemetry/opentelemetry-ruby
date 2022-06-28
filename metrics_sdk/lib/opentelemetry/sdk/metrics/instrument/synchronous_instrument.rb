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
          def initialize(name, unit, description, instrumentation_library, meter_provider)
            @name = name
            @unit = unit
            @description = description
            @instrumentation_library = instrumentation_library
            @meter_provider = meter_provider
            @metric_streams = []

            meter_provider.metric_readers.each do |metric_reader|
              register_with_new_metric_store(metric_reader.metric_store)
            end
          end

          # @api private
          def register_with_new_metric_store(metric_store)
            ms = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
              @name,
              @description,
              @unit,
              instrument_kind,
              @meter_provider,
              @instrumentation_library
            )
            @metric_streams << ms
            metric_store.add_metric_stream(ms)
          end

          private

          def update(measurement, aggregation)
            @metric_streams.each do |ms|
              ms.update(measurement, aggregation)
            end
          end
        end
      end
    end
  end
end
