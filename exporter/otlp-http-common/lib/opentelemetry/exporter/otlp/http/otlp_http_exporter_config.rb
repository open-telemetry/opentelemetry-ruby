# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # OtlpHttpExporterConfig is a configuration class for the OTLP HTTP exporter.
        class OtlpHttpExporterConfig
          ERROR_MESSAGE_INVALID_HEADERS = 'headers must be a String with comma-separated URL Encoded UTF-8 k=v pairs or a Hash'

          attr_reader :tls,
                      :ssl_verify_mode,
                      :compression,
                      :timeout,
                      :headers

          attr_accessor :endpoint

          def initialize(
            certificate_file: nil,
            client_certificate_file: nil,
            client_key_file: nil,
            ssl_verify_mode: nil,
            endpoint: nil,
            tls: nil,
            compression: nil,
            timeout: nil,
            headers: nil,
            headers_list: nil
          )
            @explicit_configuration = certificate_file ||
                                      client_certificate_file ||
                                      client_key_file ||
                                      ssl_verify_mode ||
                                      endpoint ||
                                      tls ||
                                      compression ||
                                      timeout ||
                                      headers ||
                                      headers_list
            @tls = tls || OpenTelemetry::Exporter::OTLP::HTTP::HttpTlsConfig.new(ca_file: certificate_file, key_file: client_key_file, cert_file: client_certificate_file)
            @ssl_verify_mode = ssl_verify_mode || 'none'
            @endpoint = endpoint
            @timeout = (timeout || 10).to_f
            @compression = compression || 'none'
            @headers = prepare_headers(headers, headers_list)
          end

          # Load configuration from environment variables. This method will only load configuration if no explicit configuration has been provided.
          def load_from_env(service)
            return unless @explicit_configuration.nil?

            @tls = OpenTelemetry::Exporter::OTLP::HTTP::HttpTlsConfig.new(
              ca_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CERTIFICATE", 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
              cert_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CLIENT_CERTIFICATE", 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
              key_file: OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_CLIENT_KEY", 'OTEL_EXPORTER_OTLP_CLIENT_KEY')
            )
            @ssl_verify_mode = parse_ssl_verify_mode
            @compression = OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_COMPRESSION", 'OTEL_EXPORTER_OTLP_COMPRESSION', default: 'gzip')
            @timeout = OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_TIMEOUT", 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10).to_f
            @headers = prepare_headers(nil, OpenTelemetry::Common::Utilities.config_opt("OTEL_EXPORTER_OTLP_#{service}_HEADERS", 'OTEL_EXPORTER_OTLP_HEADERS', default: nil))
            self
          end

          private

          def prepare_headers(raw_config, raw_string)
            headers = case raw_config
                      when nil
                        []
                      when Hash
                        raw_config.map do |key, value|
                          { name: key, value: value }
                        end
                      when Array
                        raw_config
                      when String
                        parse_headers(raw_config)
                      else
                        raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
                      end

            headers.concat(parse_headers(raw_string)) if raw_string
            headers
          end

          def parse_headers(raw)
            entries = raw.split(',')
            raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if entries.empty?

            entries.map do |entry|
              k, v = entry.split('=', 2).map { |part| URI.decode_uri_component(part) }
              begin
                k = k.to_s.strip
                v = v.to_s.strip
              rescue Encoding::CompatibilityError
                raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
              rescue ArgumentError => e
                raise e, ERROR_MESSAGE_INVALID_HEADERS
              end
              raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if k.empty? || v.empty?

              { name: k, value: v }
            end
          end

          # rubocop:disable-next Lint/DuplicateBranch
          def parse_ssl_verify_mode
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
