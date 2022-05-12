# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module State
        class MetricStoreRegistry
          def initialize(resource)
            @resource = resource
            @metric_stores = []
          end

          def add_metric_store
            new_metric_store = MetricStore.new
            @metric_stores = @metric_stores.dup.push(new_metric_store)
            new_metric_store
          end

          def produce(measurement, instrument)
            # Info we need to build a metric:
            # measurement
            # @meter_provider.resource
            # instrument.class? or a symbol representing the instrument 'kind' from Meter.create_instrument
            # instrument.name
            # instrument.unit
            # instrument.description
            # instrument.instrumentation_library

            # TODO: once we add views
            # instrument.views do |view|
            #   view.metrics(measurement, instrument, @meter_provider.resource) do |metric|
            #     @metric_stores.each { |ms| ms.record(metric) }
            #   end
            # end

            # record metric stream
            @metric_stores.each { |ms| ms.record(measurement, instrument, @resource) }
          end
        end
      end
    end
  end
end
