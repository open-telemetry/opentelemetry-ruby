# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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

        def self.ssl_verify_mode
          if ENV.key?('OTEL_RUBY_EXPORTER_JAEGER_SSL_VERIFY_PEER')
            OpenSSL::SSL::VERIFY_PEER
          elsif ENV.key?('OTEL_RUBY_EXPORTER_JAEGER_SSL_VERIFY_NONE')
            OpenSSL::SSL::VERIFY_NONE
          else
            OpenSSL::SSL::VERIFY_PEER
          end
        end

        def initialize(endpoint: ENV.fetch('OTEL_EXPORTER_JAEGER_ENDPOINT', 'http://localhost:14268/api/traces'),
                       username: ENV['OTEL_EXPORTER_JAEGER_USER'],
                       password: ENV['OTEL_EXPORTER_JAEGER_PASSWORD'],
                       timeout: ENV.fetch('OTEL_EXPORTER_JAEGER_TIMEOUT', 10),
                       ssl_verify_mode: CollectorExporter.ssl_verify_mode)
          raise ArgumentError, "invalid url for Jaeger::CollectorExporter #{endpoint}" if invalid_url?(endpoint)
          raise ArgumentError, 'username and password should either both be nil or both be set' if username.nil? != password.nil?

          transport_opts = { ssl_verify_mode: Integer(ssl_verify_mode) }
          @transport = ::Thrift::HTTPClientTransport.new(endpoint, transport_opts)
          unless username.nil? || password.nil?
            authorization = Base64.strict_encode64("#{username}:#{password}")
            auth_header = { 'Authorization': "Basic #{authorization}" }
            @transport.add_headers(auth_header)
          end
          @serializer = ::Thrift::Serializer.new
          @shutdown = false
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

          encoded_batches(span_data).each do |batch|
            @transport.write(@serializer.serialize(batch))
          end

          OpenTelemetry::Common::Utilities.untraced do
            @transport.flush
          end
          SUCCESS
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in Jaeger::CollectorExporter#export')
          FAILURE
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
