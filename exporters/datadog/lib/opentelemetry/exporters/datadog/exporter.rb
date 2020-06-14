# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'
require 'ddtrace'
require 'opentelemetry/sdk'
require 'opentelemetry/exporters/datadog/exporter/span_encoder'
# require_relative './exporter/span_encoder.rb'

module OpenTelemetry
  module Exporters
    module Datadog
      # SpanExporter allows different tracing services to export
      # recorded data for sampled spans in their own format.
      #
      # To export data an exporter MUST be registered to the {TracerProvider} using
      # a {DatadogSpanProcessorr}.
      class Exporter
        DEFAULT_AGENT_URL = 'http://localhost:8126'
        DEFAULT_SERVICE_NAME = 'my_service'
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILED_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_RETRYABLE
        FAILED_NOT_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_NOT_RETRYABLE
        private_constant(:SUCCESS, :FAILED_RETRYABLE, :FAILED_NOT_RETRYABLE)

        def initialize(service_name:, agent_url:)
          @shutdown = false
          @agent_url = agent_url || ENV.fetch('DD_TRACE_AGENT_URL', DEFAULT_AGENT_URL)

          @service = service_name || ENV.fetch('DD_SERVICE', DEFAULT_SERVICE_NAME)

          @agent_writer = get_writer(@agent_url)

          @span_encoder = SpanEncoder.new
        end

        # Called to export sampled {Span}s.
        #
        # @param [Enumerable<Span>] spans the list of sampled {Span}s to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(spans)
          return FAILED_NOT_RETRYABLE if @shutdown

          datadog_spans = @span_encoder.translate_to_datadog(spans, @service)
          @agent_writer.write(datadog_spans)

          SUCCESS
        end

        # Called when {TracerProvider#shutdown} is called, if this exporter is
        # registered to a {TracerProvider} object.
        def shutdown
          @shutdown = true
        end

        private

        def get_writer(uri)
          uri_parsed = URI.parse(uri)

          if %w[http https].include?(uri_parsed.scheme)
            hostname = uri_parsed.hostname
            port = uri_parsed.port
            @agent_writer = ::Datadog::Writer.new(hostname: hostname, port: port)
          else
            # TODO: handle uds path
            OpenTelemetry.logger.warn('only http/https is supported at this time')
          end
        end
      end
    end
  end
end
