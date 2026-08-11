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
      # Parses the file referenced by +OTEL_CONFIG_FILE+, creates the components
      # it describes, and installs them as the global OpenTelemetry state.
      #
      # @return [RubySDK] the installed SDK handle
      def configure
        install(create(parse(ENV.fetch(ENV_CONFIG_FILE, nil))))
      end

      # Same as {configure}, but reads the configuration from an explicit path.
      #
      # @param path [String] path to a declarative configuration YAML file
      # @return [RubySDK] the installed SDK handle
      def configure_from_file(path)
        install(create(parse(path)))
      end

      # Parses a declarative configuration file into the configuration model.
      #
      # @param path [String, nil] path to a declarative configuration YAML file
      # @return [Model::OpenTelemetryConfiguration, nil] nil when the file is
      #   unset, missing, or invalid
      def parse(path)
        if path.to_s.empty?
          OpenTelemetry.logger.info('No OTEL_CONFIG_FILE defined.')
          return nil
        end

        content = File.read(path)
        OpenTelemetry::OtelConfig::Model::OpenTelemetryConfiguration.from_hash(YAML.safe_load(content, permitted_classes: [Date, Time]))
      rescue Errno::ENOENT => e
        OpenTelemetry.logger.error("Config file not found: #{e.message}")
        nil
      rescue Psych::SyntaxError => e
        OpenTelemetry.logger.error("YAML parse error: #{e.message}")
        nil
      end

      # Creates the components described by a configuration model without
      # modifying global OpenTelemetry state.
      #
      # @param config [Model::OpenTelemetryConfiguration, nil]
      # @return [RubySDK] a no-op backed SDK when the configuration is absent,
      #   invalid, disabled, or opentelemetry-sdk isn't loaded
      def create(config)
        return noop_sdk if config.nil?

        unless defined?(OpenTelemetry::SDK)
          warn '[opentelemetry-otelconfig] opentelemetry-sdk is not loaded. ' \
               'Add `gem "opentelemetry-sdk"` to your Gemfile.'
          return noop_sdk
        end

        if config.disabled
          OpenTelemetry.logger.info('OpenTelemetry SDK disabled by configuration.')
          return noop_sdk
        end

        resource = build_resource(config.resource)

        # tracer_provider will be noop if opentelemetry-sdk is not installed
        tracer_provider = Trace.build_tracer_provider(config.tracer_provider, resource)

        propagators = configure_propagation(config.propagator)

        configure_instrumentation(config.instrumentation_development)

        RubySDK.new(
          tracer_provider: tracer_provider,
          propagator: propagators,
          resource: resource
        )
      end

      # Assigns the components of a RubySDK to the global OpenTelemetry state.
      #
      # @param ruby_sdk [RubySDK]
      # @return [RubySDK] the same SDK handle
      def install(ruby_sdk)
        OpenTelemetry.tracer_provider = ruby_sdk.tracer_provider if ruby_sdk.tracer_provider
        OpenTelemetry.propagation = ruby_sdk.propagator if ruby_sdk.propagator
        ruby_sdk
      end

      private

      # A RubySDK backed entirely by no-op components, returned whenever
      # configuration is absent, invalid, disabled, or the SDK gem isn't loaded.
      def noop_sdk
        RubySDK.new(
          tracer_provider: OpenTelemetry::Trace::TracerProvider.new,
          propagator: OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new,
          resource: defined?(OpenTelemetry::SDK) ? OpenTelemetry::SDK::Resources::Resource.create({}) : nil
        )
      end
    end
  end
end
