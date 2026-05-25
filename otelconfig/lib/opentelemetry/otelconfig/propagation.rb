# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # OtelConfig module — propagation configuration helpers.
  module OtelConfig
    class << self
      # Configures the global text-map propagator from the propagator_cfg hash.
      def configure_propagation(propagator_cfg)
        return unless propagator_cfg

        names = extract_propagator_names(propagator_cfg)
        return if names.empty?

        propagators = names.filter_map { |name| resolve_propagator(name) }
        return if propagators.empty?

        OpenTelemetry.propagation =
          OpenTelemetry::Context::Propagation::CompositeTextMapPropagator
          .compose_propagators(propagators)
      end

      # Extracts an ordered list of propagator name strings from the config hash.
      def extract_propagator_names(cfg)
        composite = cfg['composite']
        if composite.is_a?(Array)
          return composite.flat_map { |entry| entry.is_a?(Hash) ? entry.keys : entry.to_s }
        end

        list = cfg['composite_list']
        return list.split(',').map(&:strip) if list.is_a?(String)

        []
      end

      # Returns a propagator instance for the given name, or nil with a warning.
      def resolve_propagator(name)
        case name
        when 'tracecontext'
          OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
        when 'baggage'
          OpenTelemetry::Baggage::Propagation.text_map_propagator
        when 'b3'
          const_get_propagator('OpenTelemetry::Propagator::B3::Single')
        when 'b3multi'
          const_get_propagator('OpenTelemetry::Propagator::B3::Multi')
        when 'jaeger'
          const_get_propagator('OpenTelemetry::Propagator::Jaeger')
        when 'ottrace'
          const_get_propagator('OpenTelemetry::Propagator::OTTrace')
        when 'xray'
          const_get_propagator('OpenTelemetry::Propagator::XRay')
        when 'google_cloud_trace_context'
          const_get_propagator('OpenTelemetry::Propagator::GoogleCloudTraceContext')
        else
          OpenTelemetry.logger.warn("Unknown propagator: #{name}")
          nil
        end
      end

      # Looks up a propagator class by fully-qualified name and returns its text_map_propagator.
      def const_get_propagator(class_name)
        Kernel.const_get(class_name).text_map_propagator
      rescue NameError
        OpenTelemetry.logger.warn("Propagator #{class_name} not available — is the gem installed?")
        nil
      end
    end
  end
end
