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
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        def initialize(service_name: nil, agent_url: nil, env: nil, version: nil, tags: nil)
          @shutdown = false
          @agent_url = agent_url || ENV.fetch('DD_TRACE_AGENT_URL', DEFAULT_AGENT_URL)
          @service = service_name || ENV.fetch('DD_SERVICE', DEFAULT_SERVICE_NAME)

          @env = env || ENV.fetch('DD_ENV', nil)
          @version = version || ENV.fetch('DD_VERSION', nil)
          @tags = tags || ENV.fetch('DD_TAGS', nil)

          @agent_writer = get_writer(@agent_url)

          @span_encoder = SpanEncoder.new
        end

        # Called to export sampled {Span}s.
        #
        # @param [Enumerable<Span>] spans the list of sampled {Span}s to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(spans)
          return FAILURE if @shutdown

          if @agent_writer
            datadog_spans = @span_encoder.translate_to_datadog(spans, @service, @env, @version, @tags)
            @agent_writer.write(datadog_spans)
            SUCCESS
          else
            OpenTelemetry.logger.debug('Agent writer not set')
            FAILURE
          end
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

            adapter = ::Datadog::Transport::HTTP::Adapters::Net.new(hostname, port)

            transport = ::Datadog::Transport::HTTP.default do |t|
              t.adapter adapter
            end

            ::Datadog::Writer.new(transport: transport)
          elsif uri_parsed.to_s.index('/sock')
            # handle uds path
            transport = ::Datadog::Transport::HTTP.default do |t|
              t.adapter :unix, uri_parsed.to_s
            end

            ::Datadog::Writer.new(transport: transport)
          else
            OpenTelemetry.logger.warn('only http/https and uds is supported at this time')
          end
        end
      end
    end
  end
end
