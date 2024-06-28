# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      # The ConfiguratorPatch implements a hook to configure the metrics
      # portion of the SDK.
      module ConfiguratorPatch
        def add_metric_reader(metric_reader)
          @metric_readers << metric_reader
        end

        private

        def initialize
          super
          @metric_readers = []
        end

        # The metrics_configuration_hook method is where we define the setup process
        # for metrics SDK.
        def metrics_configuration_hook
          OpenTelemetry.meter_provider = Metrics::MeterProvider.new(resource: @resource)
          configure_metric_readers
        end

        def configure_metric_readers
          readers = @metric_readers.empty? ? wrapped_metric_exporters_from_env.compact : @metric_readers
          readers.each { |r| OpenTelemetry.meter_provider.add_metric_reader(r) }
        end

        def wrapped_metric_exporters_from_env
          exporters = ENV.fetch('OTEL_METRICS_EXPORTER', 'console')

          exporters.split(',').map do |exporter|
            case exporter.strip
            when 'none' then nil
            when 'console' then OpenTelemetry.meter_provider.add_metric_reader(Metrics::Export::ConsoleMetricPullExporter.new)
            when 'otlp'
              OpenTelemetry.meter_provider.add_metric_reader(OpenTelemetry::Exporter::OTLP::MetricsExporter.new)
            else
              OpenTelemetry.logger.warn "The #{exporter} exporter is unknown and cannot be configured, metrics will not be exported"
              nil
            end
          end
        end
      end
    end
  end
end

OpenTelemetry::SDK::Configurator.prepend(OpenTelemetry::SDK::Metrics::ConfiguratorPatch)
