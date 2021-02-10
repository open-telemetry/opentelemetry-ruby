# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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

      attr_writer :logger, :extractors, :injectors, :error_handler,
                  :id_generator

      def initialize
        @instrumentation_names = []
        @instrumentation_config_map = {}
        @injectors = nil
        @extractors = nil
        @span_processors = []
        @use_mode = USE_MODE_UNSPECIFIED
        @resource = Resources::Resource.default
        @id_generator = OpenTelemetry::Trace
      end

      def logger
        @logger ||= OpenTelemetry.logger
      end

      def error_handler
        @error_handler ||= OpenTelemetry.error_handler
      end

      # Accepts a resource object that is merged with the default telemetry sdk
      # resource. The use of this method is optional, and is provided as means
      # to include additional resource information.
      # If a resource key collision occurs the passed in resource takes priority.
      #
      # @param [Resource] new_resource The resource to be merged
      def resource=(new_resource)
        @resource = @resource.merge(new_resource)
      end

      # Accepts a string that is merged in as the service.name resource attribute.
      # The most recent assigned value will be used in the event of repeated
      # calls to this setter.
      # @param [String] service_name The value to be used as the service name
      def service_name=(service_name)
        self.resource = OpenTelemetry::SDK::Resources::Resource.create(
          OpenTelemetry::SDK::Resources::Constants::SERVICE_RESOURCE[:name] => service_name
        )
      end

      # Accepts a string that is merged in as the service.version resource attribute.
      # The most recent assigned value will be used in the event of repeated
      # calls to this setter.
      # @param [String] service_version The value to be used as the service version
      def service_version=(service_version)
        self.resource = OpenTelemetry::SDK::Resources::Resource.create(
          OpenTelemetry::SDK::Resources::Constants::SERVICE_RESOURCE[:version] => service_version
        )
      end

      # Install an instrumentation with specificied optional +config+.
      # Use can be called multiple times to install multiple instrumentation.
      # Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use_all+ after +use+ will result in an
      # exception.
      #
      # @param [String] instrumentation_name The name of the instrumentation
      # @param [optional Hash] config The config for this instrumentation
      def use(instrumentation_name, config = nil)
        check_use_mode!(USE_MODE_ONE)
        @instrumentation_names << instrumentation_name
        @instrumentation_config_map[instrumentation_name] = config if config
      end

      # Install all registered instrumentation. Configuration for specific
      # instrumentation can be provided with the optional +instrumentation_config_map+
      # parameter. Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use+ after +use_all+ will result in an
      # exception.
      #
      # @param [optional Hash<String,Hash>] instrumentation_config_map A map with string keys
      #   representing the instrumentation name and values specifying the instrumentation config
      def use_all(instrumentation_config_map = {})
        check_use_mode!(USE_MODE_ALL)
        @instrumentation_config_map = instrumentation_config_map
      end

      # Add a span processor to the export pipeline
      #
      # @param [#on_start, #on_finish, #shutdown, #force_flush] span_processor A span_processor
      #   that satisfies the duck type #on_start, #on_finish, #shutdown, #force_flush. See
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
        OpenTelemetry.error_handler = error_handler
        OpenTelemetry.baggage = Baggage::Manager.new
        configure_propagation
        configure_span_processors
        tracer_provider.id_generator = @id_generator
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
          OpenTelemetry.instrumentation_registry.install(@instrumentation_names, @instrumentation_config_map)
        when USE_MODE_ALL
          OpenTelemetry.instrumentation_registry.install_all(@instrumentation_config_map)
        end
      end

      def configure_span_processors
        processors = @span_processors.empty? ? [default_span_processor] : @span_processors
        processors.each { |p| tracer_provider.add_span_processor(p) }
      end

      def default_span_processor
        Trace::Export::SimpleSpanProcessor.new(configured_exporter)
      end

      def configured_exporter
        exporter = ENV.fetch('OTEL_TRACES_EXPORTER', 'otlp')
        case exporter
        when 'otlp' then otlp_exporter
        when 'jaeger' then jaeger_exporter
        when 'zipkin' then zipkin_exporter
        else
          OpenTelemetry.logger.warn "The #{exporter} exporter is unknown and cannot be configured, configuring the console exporter instead"
          Trace::Export::ConsoleSpanExporter.new
        end
      end

      def configure_propagation # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        propagators = ENV.fetch('OTEL_PROPAGATORS', 'tracecontext,baggage').split(',')
        injectors, extractors = propagators.uniq.collect do |propagator|
          case propagator
          when 'tracecontext'
            [OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector, OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor]
          when 'baggage'
            [OpenTelemetry::Baggage::Propagation.text_map_injector, OpenTelemetry::Baggage::Propagation.text_map_extractor]
          when 'b3' then b3_single_propagator
          when 'b3multi' then b3_multi_propagator
          when 'jaeger' then jaeger_propagator
          when 'xray' then xray_propagator
          when 'ottrace' then ot_trace_propagator
          else
            OpenTelemetry.logger.warn "The #{propagator} propagator is unknown and cannot be configured"
            [nil, nil]
          end
        end.transpose
        OpenTelemetry.propagation = create_propagator(@injectors || injectors.compact,
                                                      @extractors || extractors.compact)
      end

      def create_propagator(injectors, extractors)
        if injectors.size > 1 || extractors.size > 1
          Context::Propagation::CompositePropagator.new(injectors, extractors)
        else
          Context::Propagation::Propagator.new(injectors, extractors)
        end
      end

      def b3_single_propagator
        if defined?(OpenTelemetry::Propagator::B3::Single)
          [OpenTelemetry::Propagator::B3::Single.text_map_injector, OpenTelemetry::Propagator::B3::Single.text_map_extractor]
        else
          unavailable_external_propagator 'b3'
        end
      end

      def b3_multi_propagator
        if defined?(OpenTelemetry::Propagator::B3::Multi)
          [OpenTelemetry::Propagator::B3::Multi.text_map_injector, OpenTelemetry::Propagator::B3::Multi.text_map_extractor]
        else
          unavailable_external_propagator 'b3multi', 'b3'
        end
      end

      def jaeger_propagator
        if defined?(OpenTelemetry::Propagator::Jaeger)
          [OpenTelemetry::Propagator::Jaeger.text_map_injector, OpenTelemetry::Propagator::Jaeger.text_map_extractor]
        else
          unavailable_external_propagator 'jaeger'
        end
      end

      def xray_propagator
        if defined?(OpenTelemetry::Propagator::XRay)
          [OpenTelemetry::Propagator::XRay.text_map_injector, OpenTelemetry::Propagator::XRay.text_map_extractor]
        else
          unavailable_external_propagator 'xray'
        end
      end

      def ot_trace_propagator
        if defined?(OpenTelemetry::Propagator::OTTrace)
          [OpenTelemetry::Propagator::OTTrace.text_map_injector, OpenTelemetry::Propagator::OTTrace.text_map_extractor]
        else
          unavailable_external_propagator 'ottrace'
        end
      end

      def unavailable_external_propagator(name, gem_suffix = name)
        OpenTelemetry.logger.warn "The #{name} propagator cannot be configured - please add opentelemetry-propagator-#{gem_suffix} to your Gemfile"
        [nil, nil]
      end

      def otlp_exporter
        return OpenTelemetry::Exporter::OTLP::Exporter.new if defined?(OpenTelemetry::Exporter::OTLP)

        unavailable_external_exporter 'otlp'
      end

      def jaeger_exporter
        return OpenTelemetry::Exporter::Jaeger::CollectorExporter.new if defined?(OpenTelemetry::Exporter::Jaeger)

        unavailable_external_exporter 'jaeger'
      end

      def zipkin_exporter
        return OpenTelemetry::Exporter::Zipkin::Exporter.new if defined?(OpenTelemetry::Exporter::Zipkin)

        unavailable_external_exporter 'zipkin'
      end

      def unavailable_external_exporter(name)
        OpenTelemetry.logger.warn "The #{name} exporter cannot be configured - please add opentelemetry-exporter-#{name} to your Gemfile, configuring the console exporter instead"
        Trace::Export::ConsoleSpanExporter.new
      end
    end
  end
end
