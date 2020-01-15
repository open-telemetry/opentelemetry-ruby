# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The configurator provides defaults and facilitates configuring the
    # SDK for use.
    class Configurator
      USE_MODE_UNSPECIFIED = 0
      USE_MODE_ONE = 1
      USE_MODE_ALL = 2

      private_constant :USE_MODE_UNSPECIFIED, :USE_MODE_ONE, :USE_MODE_ALL

      attr_writer :tracer_factory, :meter_factory, :correlation_context_manager,
                  :propagation, :logger

      def initialize
        @adapter_names = []
        @adapter_config_map = {}
        @span_processors = []
        @use_mode = USE_MODE_UNSPECIFIED
      end

      def tracer_factory
        @tracer_factory ||= Trace::TracerFactory.new
      end

      # These exist in open or future PRs | | |
      #                                   v v v
      # def meter_factory
      #   @meter_factory ||= Metrics::MeterFactory.new
      # end

      # def correlation_context_manager
      #   @correlation_context_manager ||= CorrelationContext::Mangager.new
      # end

      # def propagation
      #   @propagation ||= Propagation::Propagation.new
      # end

      def logger
        @logger ||= Logger.new(STDOUT)
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
      # @param [Hash<String,Hash>] adapter_config_map A map with string keys
      #   representing the adapter name and values specifying the adapter config
      def use_all(adapter_config_map = {})
        check_use_mode!(USE_MODE_ALL)
        @adapter_config_map = adapter_config_map
      end

      def add_span_processor(span_processor)
        @span_processors << span_processor
      end

      # @api private
      # The configure method is where we define the setup process. This allows
      # us to make certain guarantees about which systems and globals are setup
      # at each stage. Currently, the setup process is roughly:
      #   - setup logging
      #   - setup propagation
      #   - setup tracer_factory and meter_factory
      #   - install instrumentation
      def configure
        OpenTelemetry.logger = logger
        # These exist in open or future PRs | | |
        #                                   v v v
        # OpenTelemetry.correlation_context_manager = correlation_context_manager
        # OpenTelemetry.propagation = propagation
        configure_span_processors
        OpenTelemetry.tracer_factory = tracer_factory
        # These exist in open or future PRs | | |
        #                                   v v v
        # OpenTelemetry.meter_factory = meter_factory
        # install_instrumentation
      end

      private

      def check_use_mode!(mode)
        @use_mode = mode if @use_mode == USE_MODE_UNSPECIFIED
        raise 'Use either `use_all` or `use`, but not both' unless @use_mode == mode
      end

      def install_instrumentation
        case @use_mode
        when USE_MODE_ONE
          OpenTelemetry.instrumentation_registry.install(@adapter_names, @adapter_config_map)
        when USE_MODE_ALL
          OpenTelemtry.instrumentation_registry.install_all(@adapter_config_map)
        end
      end

      def configure_span_processors
        processors = @span_processors.empty? ? [default_span_processor] : @span_processors
        processors.each { |p| tracer_factory.add_span_processor(p) }
      end

      def default_span_processor
        Trace::Export::SimpleSpanProcessor.new(
          Trace::Export::ConsoleSpanExporter.new
        )
      end
    end
  end
end
