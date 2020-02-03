# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

$LOAD_PATH.push(File.dirname(__FILE__) + '/../../../../thrift/gen-rb')

require 'agent'
require 'opentelemetry/sdk'
require 'socket'

module OpenTelemetry
  module Exporters
    module Jaeger
      # An OpenTelemetry trace exporter that sends spans over UDP as Thrift Compact encoded Jaeger spans.
      class Exporter # rubocop:disable Metrics/ClassLength
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILED_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_RETRYABLE
        FAILED_NOT_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_NOT_RETRYABLE
        private_constant(:SUCCESS, :FAILED_RETRYABLE, :FAILED_NOT_RETRYABLE)

        def initialize(service_name:, host:, port:, max_packet_size: 65_000)
          transport = Transport.new(host, port)
          protocol = ::Thrift::CompactProtocol.new(transport)
          @client = Thrift::Agent::Client.new(protocol)
          @max_packet_size = max_packet_size
          @shutdown = false
          @service_name = service_name
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @return [Integer] the result of the export.
        def export(span_data)
          return FAILED_NOT_RETRYABLE if @shutdown

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
          encoded_spans = span_data.map(&method(:encoded_span))
          encoded_span_sizes = encoded_spans.map(&method(:encoded_span_size))
          return FAILED_NOT_RETRYABLE if encoded_span_sizes.any? { |size| size > @max_packet_size }

          encoded_spans.zip(encoded_span_sizes).chunk(&batcher).each do |batch_and_spans_with_size|
            yield Thrift::Batch.new('process' => encoded_process, 'spans' => batch_and_spans_with_size.last.map(&:first))
          end
          SUCCESS
        end

        def encoded_span(span_data) # rubocop:disable Metrics/AbcSize
          start_time = (span_data.start_timestamp.to_f * 1_000_000).to_i
          duration = (span_data.end_timestamp.to_f * 1_000_000).to_i - start_time

          Thrift::Span.new(
            'traceIdLow' => int64(span_data.trace_id[16, 16]),
            'traceIdHigh' => int64(span_data.trace_id[0, 16]),
            'spanId' => int64(span_data.span_id),
            'parentSpanId' => int64(span_data.parent_span_id),
            'operationName' => span_data.name,
            'references' => encoded_references(span_data.links),
            'flags' => span_data.trace_flags.sampled? ? 1 : 0,
            'startTime' => start_time,
            'duration' => duration,
            'tags' => encoded_tags(span_data.attributes) + encoded_status(span_data.status) + encoded_kind(span_data.kind),
            'logs' => encoded_logs(span_data.events)
          )
        end

        def encoded_logs(events)
          events&.map do |event|
            Thrift::Log.new(
              'timestamp' => (event.timestamp.to_f * 1_000_000).to_i,
              'fields' => encoded_tags(event.attributes) + encoded_tags('name' => event.name)
            )
          end
        end

        def encoded_references(links)
          links&.map do |link|
            Thrift::SpanRef.new(
              'refType' => Thrift::SpanRefType::CHILD_OF,
              'traceIdLow' => int64(link.context.trace_id[16, 16]),
              'traceIdHigh' => int64(link.context.trace_id[0, 16]),
              'spanId' => int64(link.context.span_id)
            )
          end
        end

        EMPTY_ARRAY = [].freeze
        LONG = Thrift::Tag::FIELDS[Thrift::Tag::VLONG][:name]
        DOUBLE = Thrift::Tag::FIELDS[Thrift::Tag::VDOUBLE][:name]
        STRING = Thrift::Tag::FIELDS[Thrift::Tag::VSTR][:name]
        BOOL = Thrift::Tag::FIELDS[Thrift::Tag::VBOOL][:name]
        KEY = Thrift::Tag::FIELDS[Thrift::Tag::KEY][:name]
        TYPE = Thrift::Tag::FIELDS[Thrift::Tag::VTYPE][:name]
        private_constant(:EMPTY_ARRAY, :LONG, :DOUBLE, :STRING, :BOOL, :KEY, :TYPE)

        def encoded_tags(attributes)
          @type_map ||= {
            LONG => Thrift::TagType::LONG,
            DOUBLE => Thrift::TagType::DOUBLE,
            STRING => Thrift::TagType::STRING,
            BOOL => Thrift::TagType::BOOL
          }.freeze

          attributes&.map do |key, value|
            value_key = case value
                        when Integer then LONG
                        when Float then DOUBLE
                        when String then STRING
                        when false, true then BOOL
                        end
            Thrift::Tag.new(
              KEY => key,
              TYPE => @type_map[value_key],
              value_key => value
            )
          end || EMPTY_ARRAY
        end

        def encoded_status(status)
          # TODO: OpenTracing doesn't specify how to report non-HTTP (i.e. generic) status.
          EMPTY_ARRAY
        end

        def encoded_kind(kind)
          @kind_map ||= {
            OpenTelemetry::Trace::SpanKind::SERVER => 'server',
            OpenTelemetry::Trace::SpanKind::CLIENT => 'client',
            OpenTelemetry::Trace::SpanKind::PRODUCER => 'producer',
            OpenTelemetry::Trace::SpanKind::CONSUMER => 'consumer'
          }.freeze

          value = @kind_map[kind]
          if value
            Array(
              Thrift::Tag.new(
                KEY => 'span.kind',
                TYPE => Thrift::TagType::STRING,
                STRING => value
              )
            )
          else
            EMPTY_ARRAY
          end
        end

        def int64(hex_string)
          int = hex_string.to_i(16)
          int < (1 << 63) ? int : int - (1 << 64)
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
          @transport ||= SizingTransport.new
          @protocol ||= ::Thrift::CompactProtocol.new(@transport)
          @transport.flush
          encoded_span.write(@protocol)
          @transport.size
        end

        def encoded_process
          @encoded_process ||= begin
            tags = [] # TODO: figure this out.
            # tags = OpenTelemetry.tracer.resource.label_enumerator.map do |key, value|
            #   Thrift::Tag.new('key' => key, 'vType' => Thrift::TagType::STRING, 'vStr' => value)
            # end
            Thrift::Process.new('serviceName' => @service_name, 'tags' => tags)
          end
        end
      end
    end
  end
end
