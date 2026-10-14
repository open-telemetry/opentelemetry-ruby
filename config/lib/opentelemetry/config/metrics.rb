# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Config
    # Metrics component builder for configuring MeterProvider from declarative config.
    module Metrics
      PER_KIND_CARDINALITY_LIMITS = %i[
        counter gauge histogram observable_counter observable_gauge observable_up_down_counter up_down_counter
      ].freeze
      private_constant :PER_KIND_CARDINALITY_LIMITS

      module_function

      # Builds a MeterProvider from the parsed YAML meter_provider config.
      # Returns nil if config is nil or opentelemetry-metrics-sdk isn't loaded.
      def build_meter_provider(config, resource)
        return unless config

        unless defined?(OpenTelemetry::SDK::Metrics::MeterProvider)
          OpenTelemetry.logger.warn('meter_provider is configured but opentelemetry-metrics-sdk is not loaded. ' \
                                    'Add `gem "opentelemetry-metrics-sdk"` to your Gemfile.')
          return
        end

        mp = OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: resource)
        exemplar_filter = build_exemplar_filter(config.exemplar_filter)
        mp.enable_exemplar_filter(exemplar_filter: exemplar_filter) if exemplar_filter

        Array(config.readers).each do |reader_cfg|
          mp.add_metric_reader(build_metric_reader(reader_cfg))
        rescue StandardError => e
          OpenTelemetry.logger.warn("Failed to build metric reader: #{e.message}")
        end

        mp
      end

      # Builds a metric reader from config; only periodic readers are supported.
      def build_metric_reader(reader_cfg)
        raise ArgumentError, 'must not specify multiple metric reader types' if reader_cfg.periodic && reader_cfg.pull
        raise ArgumentError, 'pull metric readers are not supported' if reader_cfg.pull
        raise ArgumentError, 'unsupported metric reader type, must be periodic' unless reader_cfg.periodic

        build_periodic_metric_reader(reader_cfg.periodic)
      end

      # Builds a PeriodicMetricReader with exporter and optional tuning options.
      def build_periodic_metric_reader(cfg)
        warn_unsupported('producers') unless Array(cfg.producers).empty?

        exporter = build_metric_exporter(cfg.exporter)
        opts = {
          export_interval_millis: cfg.interval&.to_f,
          export_timeout_millis: cfg.timeout&.to_f,
          aggregation_cardinality_limit: build_cardinality_limit(cfg.cardinality_limits)
        }.compact

        OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: exporter, **opts)
      end

      # Builds a push metric exporter from config; supports console and otlp_http.
      def build_metric_exporter(exp_cfg)
        raise ArgumentError, 'no exporter config' unless exp_cfg
        raise ArgumentError, 'otlp_grpc metric exporter is not supported' if exp_cfg.otlp_grpc
        raise ArgumentError, 'otlp_file/development metric exporter is not supported' if exp_cfg.otlp_file_development

        configured = 0
        exporter   = nil

        if exp_cfg.console
          configured += 1
          warn_unsupported_exporter_options(exp_cfg.console)
          exporter = OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter.new
        end

        if exp_cfg.otlp_http
          configured += 1
          warn_unsupported_exporter_options(exp_cfg.otlp_http)
          exporter = build_otlp_http_metric_exporter(exp_cfg.otlp_http)
        end

        raise ArgumentError, 'must not specify multiple exporters' if configured > 1
        raise ArgumentError, 'no valid metric exporter'            if exporter.nil?

        exporter
      end

      # Builds an OTLP HTTP metric exporter from the given endpoint, headers, and TLS config.
      def build_otlp_http_metric_exporter(cfg)
        unless defined?(OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter)
          raise ArgumentError, 'otlp_http requires opentelemetry-exporter-otlp-metrics. ' \
                               'Add `gem "opentelemetry-exporter-otlp-metrics"` to your Gemfile.'
        end

        warn_unsupported('encoding: json') if cfg.encoding == 'json'

        headers = Trace.headers_to_hash(cfg)
        opts = {
          endpoint: cfg.endpoint,
          certificate_file: cfg.tls&.ca_file,
          client_certificate_file: cfg.tls&.cert_file,
          client_key_file: cfg.tls&.key_file,
          headers: headers.empty? ? nil : headers,
          compression: cfg.compression,
          timeout: cfg.timeout && (cfg.timeout / 1000.0)
        }.compact

        OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new(**opts)
      end

      # Warns about exporter options the metrics SDK can't apply per reader.
      def warn_unsupported_exporter_options(cfg)
        warn_unsupported('temporality_preference') if cfg.temporality_preference
        warn_unsupported('default_histogram_aggregation') if cfg.default_histogram_aggregation
      end

      # Returns the reader-wide cardinality limit. The SDK applies one limit per
      # reader, so per-instrument-kind limits are ignored.
      def build_cardinality_limit(cfg)
        return unless cfg

        PER_KIND_CARDINALITY_LIMITS.each { |kind| warn_unsupported("cardinality_limits.#{kind}") if cfg[kind] }

        cfg.default
      end

      # Logs that a configured meter_provider setting has no effect.
      def warn_unsupported(setting)
        OpenTelemetry.logger.warn("Ignoring unsupported meter_provider setting: #{setting}")
      end

      # Returns the exemplar filter for the configured name, or nil when unset or unknown.
      def build_exemplar_filter(name)
        e = OpenTelemetry::SDK::Metrics::Exemplar

        case name
        when nil then nil
        when 'trace_based' then e::TraceBasedExemplarFilter
        when 'always_on' then e::AlwaysOnExemplarFilter
        when 'always_off' then e::AlwaysOffExemplarFilter
        else
          OpenTelemetry.logger.warn("Unknown exemplar_filter #{name}. Ignoring.")
          nil
        end
      end
    end

    private_constant :Metrics
  end
end
