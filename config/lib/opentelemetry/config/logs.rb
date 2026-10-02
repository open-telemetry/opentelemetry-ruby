# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Config
    # Logs component builder for configuring LoggerProvider from declarative config.
    module Logs
      module_function

      # Builds a LoggerProvider from the parsed YAML logger_provider config.
      # Returns nil if config is nil or opentelemetry-logs-sdk isn't loaded.
      def build_logger_provider(config, resource)
        return unless config

        unless defined?(OpenTelemetry::SDK::Logs)
          OpenTelemetry.logger.warn('logger_provider is configured but opentelemetry-logs-sdk is not loaded. ' \
                                    'Add `gem "opentelemetry-logs-sdk"` to your Gemfile.')
          return
        end

        lp = OpenTelemetry::SDK::Logs::LoggerProvider.new(
          resource: resource,
          log_record_limits: build_log_record_limits(config.limits)
        )

        Array(config.processors).each do |proc_cfg|
          lp.add_log_record_processor(build_log_record_processor(proc_cfg))
        rescue StandardError => e
          OpenTelemetry.logger.warn("Failed to build log record processor: #{e.message}")
        end

        lp
      end

      # Builds a log record processor (simple or batch) from config.
      def build_log_record_processor(proc_cfg)
        raise ArgumentError, 'must not specify multiple log record processor type' if proc_cfg.batch && proc_cfg.simple

        if proc_cfg.batch
          build_batch_log_record_processor(proc_cfg.batch)
        elsif proc_cfg.simple
          build_simple_log_record_processor(proc_cfg.simple)
        else
          raise ArgumentError, 'unsupported log record processor type, must be one of simple or batch'
        end
      end

      # Builds a BatchLogRecordProcessor with exporter and optional tuning options.
      def build_batch_log_record_processor(cfg)
        exporter = build_log_record_exporter(cfg.exporter)
        opts = {
          schedule_delay: cfg.schedule_delay&.to_f,
          exporter_timeout: cfg.export_timeout&.to_f,
          max_queue_size: cfg.max_queue_size&.to_i,
          max_export_batch_size: cfg.max_export_batch_size&.to_i
        }.compact

        OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(exporter, **opts)
      end

      # Builds a SimpleLogRecordProcessor wrapping the configured exporter.
      def build_simple_log_record_processor(cfg)
        OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(build_log_record_exporter(cfg.exporter))
      end

      # Builds a log record exporter from config; supports console and otlp_http.
      def build_log_record_exporter(exp_cfg)
        raise ArgumentError, 'no exporter config' unless exp_cfg

        configured = 0
        exporter   = nil

        if exp_cfg.console
          configured += 1
          exporter = OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter.new
        end

        if exp_cfg.otlp_http
          configured += 1
          exporter = build_otlp_http_log_record_exporter(exp_cfg.otlp_http)
        end

        raise ArgumentError, 'must not specify multiple exporters' if configured > 1
        raise ArgumentError, 'no valid log record exporter'        if exporter.nil?

        exporter
      end

      # Builds an OTLP HTTP log record exporter from the given endpoint/headers config.
      def build_otlp_http_log_record_exporter(cfg)
        unless defined?(OpenTelemetry::Exporter::OTLP::Logs::LogsExporter)
          raise ArgumentError, 'otlp_http requires opentelemetry-exporter-otlp-logs. ' \
                               'Add `gem "opentelemetry-exporter-otlp-logs"` to your Gemfile.'
        end

        headers = Trace.headers_to_hash(cfg)
        opts = {
          endpoint: cfg.endpoint,
          headers: headers.empty? ? nil : headers,
          compression: cfg.compression,
          timeout: cfg.timeout && (cfg.timeout / 1000.0)
        }.compact

        OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new(**opts)
      end

      # Builds LogRecordLimits from config; returns the SDK default when config is nil.
      def build_log_record_limits(limits_cfg)
        return OpenTelemetry::SDK::Logs::LogRecordLimits::DEFAULT unless limits_cfg

        opts = {
          attribute_count_limit: limits_cfg.attribute_count_limit,
          attribute_length_limit: limits_cfg.attribute_value_length_limit
        }.compact

        OpenTelemetry::SDK::Logs::LogRecordLimits.new(**opts)
      end
    end

    private_constant :Logs
  end
end
