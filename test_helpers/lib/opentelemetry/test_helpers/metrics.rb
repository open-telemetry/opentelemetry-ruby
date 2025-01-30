# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'minitest/spec'

module OpenTelemetry
  module TestHelpers
    # Convenience features and Minitest extensions to support testing
    # around the metrics-api or metrics-sdk libraries.
    module Metrics
      module LoadedMetricsFeatures
        OTEL_METRICS_API_LOADED = !Gem.loaded_specs['opentelemetry-metrics-api'].nil?
        OTEL_METRICS_SDK_LOADED = !Gem.loaded_specs['opentelemetry-metrics-sdk'].nil?

        extend self

        def api_loaded?
          OTEL_METRICS_API_LOADED
        end

        def sdk_loaded?
          OTEL_METRICS_SDK_LOADED
        end
      end

      module MinitestExtensions
        def self.prepended(base)
          base.extend(self)
        end

        def self.included(base)
          base.extend(self)
        end

        def before_setup
          super
          reset_metrics_exporter
        end

        def with_metrics_sdk
          yield if LoadedMetricsFeatures.sdk_loaded?
        end

        def without_metrics_sdk
          yield unless LoadedMetricsFeatures.sdk_loaded?
        end

        def metrics_exporter
          with_metrics_sdk { METRICS_EXPORTER }
        end

        def reset_meter_provider
          with_metrics_sdk do
            resource = OpenTelemetry.meter_provider.resource
            OpenTelemetry.meter_provider = OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: resource)
            OpenTelemetry.meter_provider.add_metric_reader(METRICS_EXPORTER)
          end
        end

        def reset_metrics_exporter
          with_metrics_sdk do
            METRICS_EXPORTER.pull
            METRICS_EXPORTER.reset
          end
        end

        def it(desc = 'anonymous', with_metrics_sdk: false, without_metrics_sdk: false, &block)
          return super(desc, &block) unless with_metrics_sdk || without_metrics_sdk

          raise ArgumentError, 'without_metrics_sdk and with_metrics_sdk must be mutually exclusive' if without_metrics_sdk && with_metrics_sdk

          return if with_metrics_sdk && !LoadedMetricsFeatures.sdk_loaded?
          return if without_metrics_sdk && LoadedMetricsFeatures.sdk_loaded?

          super(desc, &block)
        end
      end

      if LoadedMetricsFeatures.sdk_loaded?
        METRICS_EXPORTER = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
        OpenTelemetry.meter_provider.add_metric_reader(METRICS_EXPORTER)
      end

      Minitest::Spec.prepend(MinitestExtensions)
    end
  end
end
