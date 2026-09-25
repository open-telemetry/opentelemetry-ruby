# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'openssl'

module OpenTelemetry
  module Config
    # Trace component builder for configuring TracerProvider from declarative config.
    module Trace
      module_function

      # Builds a TracerProvider from the parsed YAML tracer_provider config.
      # Returns a noop-configured provider if config is nil.
      def build_tracer_provider(config, resource)
        return OpenTelemetry::Trace::TracerProvider.new unless config

        sampler = build_sampler(config.sampler)
        span_limits = build_span_limits(config.limits)

        tp = OpenTelemetry::SDK::Trace::TracerProvider.new(
          resource: resource,
          sampler: sampler,
          span_limits: span_limits
        )

        Array(config.processors).each do |proc_cfg|
          processor = build_span_processor(proc_cfg)
          tp.add_span_processor(processor) if processor
        rescue StandardError => e
          OpenTelemetry.logger.warn("Failed to build span processor: #{e.message}")
        end

        tp
      end

      # Builds a span processor (simple or batch) from config hash.
      def build_span_processor(proc_cfg)
        raise ArgumentError, 'must not specify multiple span processor type' if proc_cfg.batch && proc_cfg.simple

        if proc_cfg.batch
          build_batch_span_processor(proc_cfg.batch)
        elsif proc_cfg.simple
          build_simple_span_processor(proc_cfg.simple)
        else
          raise ArgumentError, 'unsupported span processor type, must be one of simple or batch'
        end
      end

      # Builds a BatchSpanProcessor with exporter and schema defaults. Passing
      # every option explicitly prevents the SDK initializer from reading OTEL_*.
      def build_batch_span_processor(cfg)
        exporter = build_span_exporter(cfg.exporter)
        opts = {
          schedule_delay: cfg.schedule_delay.nil? ? 5_000 : cfg.schedule_delay.to_f,
          exporter_timeout: cfg.export_timeout.nil? ? 30_000 : cfg.export_timeout.to_f,
          max_queue_size: cfg.max_queue_size.nil? ? 2048 : cfg.max_queue_size.to_i,
          max_export_batch_size: cfg.max_export_batch_size.nil? ? 512 : cfg.max_export_batch_size.to_i,
          start_thread_on_boot: true
        }

        OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter, **opts)
      end

      # Builds a SimpleSpanProcessor wrapping the configured exporter.
      def build_simple_span_processor(cfg)
        exporter = build_span_exporter(cfg.exporter)
        OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
      end

      # Builds a span exporter from config; supports console and otlp_http.
      def build_span_exporter(exp_cfg)
        raise ArgumentError, 'no exporter config' unless exp_cfg

        configured = 0
        exporter   = nil

        if exp_cfg.console
          configured += 1
          exporter = OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
        end

        if exp_cfg.otlp_http
          configured += 1
          exporter = build_otlp_http_span_exporter(exp_cfg.otlp_http)
        end

        raise ArgumentError, 'must not specify multiple exporters' if configured > 1
        raise ArgumentError, 'no valid span exporter'              if exporter.nil?

        exporter
      end

      # Builds an OTLP HTTP span exporter from declarative values and schema
      # defaults, without falling back to exporter environment variables.
      def build_otlp_http_span_exporter(cfg)
        OpenTelemetry::Exporter::OTLP::Exporter.new(
          endpoint: cfg.endpoint || 'http://localhost:4318/v1/traces',
          certificate_file: cfg.tls&.ca_file,
          client_certificate_file: cfg.tls&.cert_file,
          client_key_file: cfg.tls&.key_file,
          ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
          headers: headers_to_hash(cfg),
          compression: cfg.compression || 'none',
          timeout: cfg.timeout.nil? ? 10.0 : (cfg.timeout / 1000.0)
        )
      end

      # Builds a sampler from config; defaults to ParentBased(ALWAYS_ON).
      def build_sampler(sampler_cfg)
        s = OpenTelemetry::SDK::Trace::Samplers

        # Default: parent-based with always_on root
        return s.parent_based(root: s::ALWAYS_ON) unless sampler_cfg

        if sampler_cfg.parent_based
          build_parent_based_sampler(sampler_cfg.parent_based)
        elsif sampler_cfg.always_on
          s::ALWAYS_ON
        elsif sampler_cfg.always_off
          s::ALWAYS_OFF
        elsif sampler_cfg.trace_id_ratio_based
          ratio = sampler_cfg.trace_id_ratio_based.ratio || 1.0
          s.trace_id_ratio_based(ratio.to_f)
        else
          s.parent_based(root: s::ALWAYS_ON)
        end
      end

      # Builds a ParentBased sampler with configurable root and remote/local delegates.
      def build_parent_based_sampler(cfg)
        s = OpenTelemetry::SDK::Trace::Samplers

        root = cfg.root ? build_sampler(cfg.root) : s::ALWAYS_ON

        opts = {
          root: root,
          remote_parent_sampled: cfg.remote_parent_sampled && build_sampler(cfg.remote_parent_sampled),
          remote_parent_not_sampled: cfg.remote_parent_not_sampled && build_sampler(cfg.remote_parent_not_sampled),
          local_parent_sampled: cfg.local_parent_sampled && build_sampler(cfg.local_parent_sampled),
          local_parent_not_sampled: cfg.local_parent_not_sampled && build_sampler(cfg.local_parent_not_sampled)
        }.compact

        s.parent_based(**opts)
      end

      # Builds SpanLimits from declarative values and schema defaults.
      def build_span_limits(limits_cfg)
        OpenTelemetry::SDK::Trace::SpanLimits.new(
          attribute_count_limit: limits_cfg&.attribute_count_limit || 128,
          attribute_length_limit: limits_cfg&.attribute_value_length_limit,
          event_count_limit: limits_cfg&.event_count_limit || 128,
          link_count_limit: limits_cfg&.link_count_limit || 128,
          event_attribute_count_limit: limits_cfg&.event_attribute_count_limit || 128,
          event_attribute_length_limit: nil,
          link_attribute_count_limit: limits_cfg&.link_attribute_count_limit || 128
        )
      end

      # Converts the OTLP exporter headers (array of NameStringValuePair structs)
      # into a flat Hash. Falls back to the comma-separated headers_list string.
      def headers_to_hash(cfg)
        headers = {}

        Array(cfg.headers).each do |pair|
          headers[pair.name] = pair.value if pair&.name
        end

        if headers.empty? && cfg.headers_list.is_a?(String)
          cfg.headers_list.split(',').each do |entry|
            key, value = entry.strip.split('=', 2)
            headers[key] = value if key && value
          end
        end

        headers
      end
    end

    private_constant :Trace
  end
end
