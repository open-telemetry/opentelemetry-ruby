# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'date'
require 'yaml'
require 'opentelemetry/components/trace'

require_relative 'otelconfig/instrumentation'
require_relative 'otelconfig/propagation'
require_relative 'otelconfig/resource'
require_relative 'constants/constants'

module OpenTelemetry
  # OtelConfig module handles declarative configuration of OpenTelemetry components
  # from YAML files.
  module OtelConfig
    ENV_CONFIG_FILE = 'OTEL_CONFIG_FILE'

    class << self
      # Entry point
      def configure
        config_path = ENV[ENV_CONFIG_FILE]

        if config_path.to_s.empty?
          OpenTelemetry.logger.info('No OTEL_CONFIG_FILE defined.')
        else
          config = parse_config_file(config_path)
          apply(config)
        end
      end

      # Configure directly from a file path (for testing or explicit setup).
      def configure_from_file(path)
        config = parse_config_file(path)
        apply(config)
      end

      private

      def apply(config)
        return if config.nil?

        unless defined?(OpenTelemetry::SDK)
          warn '[opentelemetry-otelconfig] opentelemetry-sdk is not loaded. ' \
               'Add `gem "opentelemetry-sdk"` to your Gemfile.'
          return
        end

        if config.disabled
          OpenTelemetry.logger.info('OpenTelemetry SDK disabled by configuration.')
        else
          resource = build_resource(config.resource)
          tracer_provider = Trace.build_tracer_provider(config.tracer_provider, resource)

          propagators = configure_propagation(config.propagator)

          configure_instrumentation(config.instrumentation_development)

          RubySDK.new(
            tracer_provider: tracer_provider,
            propagator: propagators,
            resource: resource
          )
        end
      end

      def parse_config_file(path)
        content = File.read(path)
        OpenTelemetryConfiguration.from_hash(YAML.safe_load(content, permitted_classes: [Date, Time]))
      rescue Errno::ENOENT => e
        OpenTelemetry.logger.error("Config file not found: #{e.message}")
        nil
      rescue Psych::SyntaxError => e
        OpenTelemetry.logger.error("YAML parse error: #{e.message}")
        nil
      end
    end
  end
end
