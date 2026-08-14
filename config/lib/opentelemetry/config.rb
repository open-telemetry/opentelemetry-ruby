# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'date'
require 'yaml'
require 'opentelemetry/components/trace'

require_relative 'config/instrumentation'
require_relative 'config/propagation'
require_relative 'config/resource'
require_relative 'constants/constants'

module OpenTelemetry
  # Config module handles declarative configuration of OpenTelemetry components
  # from YAML files.
  module Config
    ENV_CONFIG_FILE = 'OTEL_CONFIG_FILE'
    private_constant :ENV_CONFIG_FILE

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
        OpenTelemetry::Config::Model::OpenTelemetryConfiguration.from_hash(YAML.safe_load(content, permitted_classes: [Date, Time]))
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
      # @return [RubySDK] {NOOP_SDK} when the configuration is absent, invalid,
      #   disabled, or opentelemetry-sdk isn't loaded
      def create(config)
        return NOOP_SDK if config.nil?

        unless defined?(OpenTelemetry::SDK)
          warn '[opentelemetry-config] opentelemetry-sdk is not loaded. ' \
               'Add `gem "opentelemetry-sdk"` to your Gemfile.'
          return NOOP_SDK
        end

        if config.disabled
          OpenTelemetry.logger.info('OpenTelemetry SDK disabled by configuration.')
          return NOOP_SDK
        end

        resource = build_resource(config.resource)

        # tracer_provider will be noop if opentelemetry-sdk is not installed
        tracer_provider = Trace.build_tracer_provider(config.tracer_provider, resource)

        propagators = configure_propagation(config.propagator)

        RubySDK.new(
          tracer_provider: tracer_provider,
          propagator: propagators,
          resource: resource,
          instrumentation: build_instrumentation_config_map(config.instrumentation_development)
        )
      end

      # Assigns the components of a RubySDK to the global OpenTelemetry state and
      # installs the configured instrumentation libraries. NOOP_SDK will skip installation
      # and leave the global state untouched.
      #
      # @param ruby_sdk [RubySDK]
      # @return [RubySDK] the same SDK handle
      def install(ruby_sdk)
        return ruby_sdk if ruby_sdk.equal?(NOOP_SDK)

        OpenTelemetry.tracer_provider = ruby_sdk.tracer_provider if ruby_sdk.tracer_provider
        OpenTelemetry.propagation = ruby_sdk.propagator if ruby_sdk.propagator
        install_instrumentation(ruby_sdk.instrumentation)
        ruby_sdk
      end
    end
  end
end
