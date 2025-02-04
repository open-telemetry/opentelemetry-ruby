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
          def initialize(name, unit, description, instrumentation_scope, meter_provider, **advisory_parameters)
            @name = name
            @unit = unit
            @description = description
            @instrumentation_scope = instrumentation_scope
            @meter_provider = meter_provider
            @metric_streams = []

            validate_advisory_parameters(advisory_parameters)

            meter_provider.register_synchronous_instrument(self)
          end

          # @api private
          def register_with_new_metric_store(metric_store)
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

          def aggregation
            @aggregation || default_aggregation
          end

          private

          def update(value, attributes)
            @metric_streams.each { |ms| ms.update(value, attributes) }
          end

          def validate_advisory_parameters(advisory_parameters)
            if (attributes = advisory_parameters.delete(:attributes))
              @attributes = attributes
            end

            advisory_parameters.each_key do |parameter_name|
              OpenTelemetry.logger.warn "Advisory parameter `#{parameter_name}` is not valid for instrument kind `#{instrument_kind}`; ignoring"
            end
          end
        end
      end
    end
  end
end
