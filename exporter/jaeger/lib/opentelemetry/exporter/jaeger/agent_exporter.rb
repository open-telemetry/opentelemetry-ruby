# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module Jaeger
      # An OpenTelemetry trace exporter that sends spans over UDP as Thrift Compact encoded Jaeger spans.
      class AgentExporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        def initialize(host: ENV.fetch('OTEL_EXPORTER_JAEGER_AGENT_HOST', 'localhost'),
                       port: ENV.fetch('OTEL_EXPORTER_JAEGER_AGENT_PORT', 6831),
                       timeout: ENV.fetch('OTEL_EXPORTER_JAEGER_TIMEOUT', 10),
                       max_packet_size: 65_000)
          transport = Transport.new(host, port)
          protocol = ::Thrift::CompactProtocol.new(transport)
          @client = Thrift::Agent::Client.new(protocol)
          @max_packet_size = max_packet_size
          @shutdown = false
          @sizing_transport = SizingTransport.new
          @sizing_protocol = ::Thrift::CompactProtocol.new(@sizing_transport)
          @timeout = timeout.to_f
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] the result of the export.
        def export(span_data, timeout: nil)
          return FAILURE if @shutdown

          timeout ||= @timeout
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          encoded_batches(span_data) do |batch|
            return FAILURE if @shutdown || OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)&.zero?

            @client.emitBatch(batch)
          end
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def force_flush(timeout: nil)
          SUCCESS
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
          SUCCESS
        end

        private

        def batcher
          batch = 0
          batch_size = 0
          ->(arr) { # rubocop:disable Style/Lambda
            span_size = arr.last
            if batch_size + span_size > @max_packet_size
              batch_size = 0
              batch += 1
            end
            batch_size += span_size
            batch
          }
        end

        # Yields Thrift-encoded batches of spans. Batches are limited to @max_packet_size.
        # If a single span exceeds @max_packet_size, FAILURE will be returned and the
        # remaining batches will be discarded. Returns SUCCESS after all batches have been
        # successfully yielded.
        def encoded_batches(span_data)
          grouped_encoded_spans = \
            span_data.each_with_object(Hash.new { |h, k| h[k] = [] }) do |span, memo|
              encoded_data = Encoder.encoded_span(span)
              encoded_size = encoded_span_size(encoded_data)
              return FAILURE if encoded_size > @max_packet_size

              memo[span.resource] << [encoded_data, encoded_size]
            end

          grouped_encoded_spans.each_pair do |resource, encoded_spans|
            process = Encoder.encoded_process(resource)
            encoded_spans.chunk(&batcher).each do |batch_and_spans_with_size|
              yield Thrift::Batch.new('process' => process, 'spans' => batch_and_spans_with_size.last.map(&:first))
            end
          end
          SUCCESS
        end

        # @api private
        class SizingTransport
          attr_accessor :size

          def initialize
            @size = 0
          end

          def write(buf)
            @size += buf.size
          end

          def flush
            @size = 0
          end

          def close; end
        end

        private_constant(:SizingTransport)

        def encoded_span_size(encoded_span)
          @sizing_transport.flush
          encoded_span.write(@sizing_protocol)
          @sizing_transport.size
        end
      end
    end
  end
end
