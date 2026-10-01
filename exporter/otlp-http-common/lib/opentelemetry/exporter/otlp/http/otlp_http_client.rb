# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'forwardable'
require 'net/http'
require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common'

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # OTLPHTTPClient is a client class for sending OTLP data over HTTP.
        class OTLPHTTPClient
          extend Forwardable

          # Default timeouts in seconds.
          KEEP_ALIVE_TIMEOUT = 30
          private_constant(:KEEP_ALIVE_TIMEOUT)

          attr_reader :http, :uri

          def_delegators :@http,
                         :request,
                         :start,
                         :finish,
                         :started?,
                         :active?,
                         :verify_mode,
                         :ca_file,
                         :cert,
                         :key,
                         :use_ssl?,
                         :address,
                         :port,
                         :read_timeout,
                         :open_timeout

          def initialize(options, service, base_path = '')
            uri = nil
            if options.nil?
              options = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(
                tls: OpenTelemetry::Exporter::OTLP::HTTP::HttpTlsConfig.new(
                  ca_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CERTIFICATE", 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                  cert_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CLIENT_CERTIFICATE", 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                  key_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CLIENT_KEY", 'OTEL_EXPORTER_OTLP_CLIENT_KEY')
                ),
                ssl_verify_mode: ssl_verify_mode
              )
              uri = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri(nil, base_path, "OTEL_EXPORTER_OTLP_#{service}_ENDPOINT", 'OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318/')
            end

            uri ||= URI(options.endpoint || "http://localhost:4318/#{base_path}")
            @http = Net::HTTP.new(uri.hostname, uri.port)
            @http.use_ssl = uri.scheme == 'https'
            @http.verify_mode = options.ssl_verify_mode
            @http.ca_file = options.tls.ca_file if options.tls.ca_file
            @http.cert = OpenSSL::X509::Certificate.new(File.read(options.tls.cert_file)) if options.tls.cert_file
            @http.key = OpenSSL::PKey::RSA.new(File.read(options.tls.key_file)) if options.tls.key_file
            @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
          end

          private

          # rubocop:disable-next Lint/DuplicateBranch
          def ssl_verify_mode
            if ENV['OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER'] == 'true'
              OpenSSL::SSL::VERIFY_PEER
            elsif ENV['OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE'] == 'true'
              OpenSSL::SSL::VERIFY_NONE
            else
              OpenSSL::SSL::VERIFY_PEER
            end
          end
        end
      end
    end
  end
end
