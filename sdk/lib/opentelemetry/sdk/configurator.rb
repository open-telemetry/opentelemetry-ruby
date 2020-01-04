# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The configurator provides defaults and facilitates configuring the
    # SDK for use.
    class Configurator
      attr_writer :tracer_factory, :meter_factory, :correlation_context_manager,
                  :propagation, :logger

      def initialize
        @adapter_config_map = {}
        @span_processors = []
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

      def use(adapter_name, config = nil)
        @adapter_config_map[adapter_name] = config
      end

      def add_span_processor(span_processor)
        @span_processors << span_processor
      end

      # @api private
      def configure
        OpenTelemetry.logger = logger
        span_processors.each { |p| tracer_factory.add_span_processor(p) }
        OpenTelemetry.tracer_factory = tracer_factory
        # These exist in open or future PRs | | |
        #                                   v v v
        # OpenTelemetry.meter_factory = meter_factory
        # OpenTelemetry.correlation_context_manager = correlation_context_manager
        # OpenTelemetry.propagation = propagation
        # OpenTelemetry::Instrumentation.registry.install_adapters(@adapter_config_map)
      end
    end
  end
end
