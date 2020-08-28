# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

$LOAD_PATH.push(File.dirname(__FILE__) + '/../../../../thrift/gen-rb')

require 'agent'
require 'opentelemetry/sdk'
require 'socket'
require 'opentelemetry/exporters/jaeger/exporter/span_encoder'

module OpenTelemetry
  module Exporters
    module Jaeger
      # An OpenTelemetry trace exporter that sends spans over UDP as Thrift Compact encoded Jaeger spans.
      class Exporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        def initialize(service_name:, host:, port:, max_packet_size: 65_000)
          transport = Transport.new(host, port)
          protocol = ::Thrift::CompactProtocol.new(transport)
          @client = Thrift::Agent::Client.new(protocol)
          @max_packet_size = max_packet_size
          @shutdown = false
          @service_name = service_name
          @span_encoder = SpanEncoder.new
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(span_data)
          return FAILURE if @shutdown

          encoded_batches(span_data) { |batch| @client.emitBatch(batch) }
        end

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        def shutdown
          @shutdown = true
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
        # If a single span exceeds @max_packet_size, FAILED_NOT_RETRYABLE will be returned
        # and the remaining batches will be discarded. Returns SUCCESS after all batches
        # have been successfully yielded.
        def encoded_batches(span_data)
          grouped_encoded_spans = \
            span_data.each_with_object(Hash.new { |h, k| h[k] = []}) do |span, memo|
              encoded_data = encoded_span(span)
              encoded_size = encoded_span_size(encoded_data)
              return FAILURE if encoded_size > @max_packet_size

              memo[span.library_resource] << [encoded_data, encoded_size]
            end

          grouped_encoded_spans.each_pair do |resource, encoded_spans|
            encoded_spans.chunk(&batcher).each do |batch_and_spans_with_size|
              yield Thrift::Batch.new('process' => encoded_process(resource), 'spans' => batch_and_spans_with_size.last.map(&:first))
            end
          end
          SUCCESS
        end

        def encoded_span(span_data)
          @span_encoder.encoded_span(span_data)
        end

        EMPTY_ARRAY = [].freeze
        LONG = Thrift::Tag::FIELDS[Thrift::Tag::VLONG][:name]
        DOUBLE = Thrift::Tag::FIELDS[Thrift::Tag::VDOUBLE][:name]
        STRING = Thrift::Tag::FIELDS[Thrift::Tag::VSTR][:name]
        BOOL = Thrift::Tag::FIELDS[Thrift::Tag::VBOOL][:name]
        KEY = Thrift::Tag::FIELDS[Thrift::Tag::KEY][:name]
        TYPE = Thrift::Tag::FIELDS[Thrift::Tag::VTYPE][:name]
        private_constant(:EMPTY_ARRAY, :LONG, :DOUBLE, :STRING, :BOOL, :KEY, :TYPE)

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
          @transport ||= SizingTransport.new
          @protocol ||= ::Thrift::CompactProtocol.new(@transport)
          @transport.flush
          encoded_span.write(@protocol)
          @transport.size
        end

        def encoded_process(resource)
          @encoded_process ||= begin
            tags = resource&.label_enumerator&.map do |key, value|
              Thrift::Tag.new('key' => key, 'vType' => Thrift::TagType::STRING, 'vStr' => value)
            end || EMPTY_ARRAY

            Thrift::Process.new('serviceName' => @service_name, 'tags' => tags)
          end
        end
      end
    end
  end
end
