# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'

module OpenTelemetry
  module Exporter
    module Jaeger
      # An OpenTelemetry trace exporter that sends spans over HTTP as Thrift Binary encoded Jaeger spans.
      class CollectorExporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        def initialize(endpoint: ENV.fetch('OTEL_EXPORTER_JAEGER_ENDPOINT', 'http://localhost:14268'),
                       username: ENV['OTEL_EXPORTER_JAEGER_USER'],
                       password: ENV['OTEL_EXPORTER_JAEGER_PASSWORD'])
          raise ArgumentError, "invalid url for Jaeger::CollectorExporter #{endpoint}" if invalid_url?(endpoint)

          transport = ::Thrift::HTTPClientTransport.new(endpoint) # TODO: how to specify username and password?
          protocol = ::Thrift::BinaryProtocol.new(transport)
          @client = Thrift::Collector::Client.new(protocol)
          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(span_data)
          return FAILURE if @shutdown

          batches = encoded_batches(span_data)
          @client.submitBatches(batches).all?(&:ok) ? SUCCESS : FAILURE
        rescue ::Thrift::ApplicationException => e
          OpenTelemetry.logger.error("unexpected error in Jaeger::CollectorExporter#export - #{e}")
          FAILURE
        end

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        def shutdown
          @shutdown = true
        end

        private

        def invalid_url?(url)
          return true if url.nil? || url.strip.empty?

          URI(url)
          false
        rescue URI::InvalidURIError
          true
        end

        def encoded_batches(span_data)
          span_data.group_by(&:resource).map do |resource, spans|
            process = Encoder.encoded_process(resource)
            spans.map! { |span| Encoder.encoded_span(span) }
            Thrift::Batch.new('process' => process, 'spans' => spans)
          end
        end
      end
    end
  end
end
