# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The configurator provides defaults and facilitates configuring the
    # SDK for use.
    class Configurator # rubocop:disable Metrics/ClassLength
      USE_MODE_UNSPECIFIED = 0
      USE_MODE_ONE = 1
      USE_MODE_ALL = 2

      private_constant :USE_MODE_UNSPECIFIED, :USE_MODE_ONE, :USE_MODE_ALL

      attr_writer :logger, :http_extractors, :http_injectors, :text_extractors,
                  :text_injectors

      def initialize
        @adapter_names = []
        @adapter_config_map = {}
        @http_extractors = nil
        @http_injectors = nil
        @text_extractors = nil
        @text_injectors = nil
        @span_processors = []
        @use_mode = USE_MODE_UNSPECIFIED
        @resource = Resources::Resource.telemetry_sdk
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      # Accepts a resource object that is merged with the default telemetry sdk
      # resource. The use of this method is optional, and is provided as means
      # to add additional resource information.
      #
      # @param [Resource] new_resource The resource to be merged
      def resource=(new_resource)
        @resource = @resource.merge(new_resource)
      end

      # Install an instrumentation adapter with specificied optional +config+.
      # Use can be called multiple times to install multiple instrumentation
      # adapters. Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use_all+ after +use+ will result in an
      # exception.
      #
      # @param [String] adapter_name The name of the instrumentation adapter
      # @param [optional Hash] config The config for this adapter
      def use(adapter_name, config = nil)
        check_use_mode!(USE_MODE_ONE)
        @adapter_names << adapter_name
        @adapter_config_map[adapter_name] = config if config
      end

      # Install all registered instrumentation. Configuration for specific
      # adapters can be provided with the optional +adapter_config_map+
      # parameter. Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use+ after +use_all+ will result in an
      # exception.
      #
      # @param [optional Hash<String,Hash>] adapter_config_map A map with string keys
      #   representing the adapter name and values specifying the adapter config
      def use_all(adapter_config_map = {})
        check_use_mode!(USE_MODE_ALL)
        @adapter_config_map = adapter_config_map
      end

      # Add a span processor to the export pipeline
      #
      # @param [#on_start, #on_finish, #shutdown] span_processor A span_processor
      #   that satisfies the duck type #on_start, #on_finish, #shutdown. See
      #   {SimpleSpanProcessor} for an example.
      def add_span_processor(span_processor)
        @span_processors << span_processor
      end

      # @api private
      # The configure method is where we define the setup process. This allows
      # us to make certain guarantees about which systems and globals are setup
      # at each stage. The setup process is:
      #   - setup logging
      #   - setup propagation
      #   - setup tracer_provider and meter_provider
      #   - install instrumentation
      def configure
        OpenTelemetry.logger = logger
        OpenTelemetry.correlations = CorrelationContext::Manager.new
        configure_propagation
        configure_span_processors
        OpenTelemetry.tracer_provider = tracer_provider
        install_instrumentation
      end

      private

      def tracer_provider
        @tracer_provider ||= Trace::TracerProvider.new(@resource)
      end

      def check_use_mode!(mode)
        @use_mode = mode if @use_mode == USE_MODE_UNSPECIFIED
        raise 'Use either `use_all` or `use`, but not both' unless @use_mode == mode
      end

      def install_instrumentation
        case @use_mode
        when USE_MODE_ONE
          OpenTelemetry.instrumentation_registry.install(@adapter_names, @adapter_config_map)
        when USE_MODE_ALL
          OpenTelemetry.instrumentation_registry.install_all(@adapter_config_map)
        end
      end

      def configure_span_processors
        processors = @span_processors.empty? ? [default_span_processor] : @span_processors
        processors.each { |p| tracer_provider.add_span_processor(p) }
      end

      def default_span_processor
        Trace::Export::SimpleSpanProcessor.new(
          Trace::Export::ConsoleSpanExporter.new
        )
      end

      def configure_propagation
        OpenTelemetry.propagation.http = create_propagator(@http_injectors || default_http_injectors,
                                                           @http_extractors || default_http_extractors)
        OpenTelemetry.propagation.text = create_propagator(@text_injectors || default_text_injectors,
                                                           @text_extractors || default_text_extractors)
      end

      def create_propagator(injectors, extractors)
        if injectors.size > 1 || extractors.size > 1
          Context::Propagation::CompositePropagator.new(injectors, extractors)
        else
          Context::Propagation::Propagator.new(injectors, extractors)
        end
      end

      def default_http_injectors
        default_text_injectors
      end

      def default_http_extractors
        [
          OpenTelemetry::Trace::Propagation::TraceContext.rack_extractor,
          OpenTelemetry::CorrelationContext::Propagation.rack_extractor
        ]
      end

      def default_text_injectors
        [
          OpenTelemetry::Trace::Propagation::TraceContext.text_injector,
          OpenTelemetry::CorrelationContext::Propagation.text_injector
        ]
      end

      def default_text_extractors
        [
          OpenTelemetry::Trace::Propagation::TraceContext.text_extractor,
          OpenTelemetry::CorrelationContext::Propagation.text_extractor
        ]
      end
    end
  end
end
