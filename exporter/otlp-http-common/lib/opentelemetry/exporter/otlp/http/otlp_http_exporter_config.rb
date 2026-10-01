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
          attr_reader :tls,
                      :ssl_verify_mode,
                      :endpoint

          def initialize(
            certificate_file: nil,
            client_certificate_file: nil,
            client_key_file: nil,
            ssl_verify_mode: nil,
            endpoint: nil,
            tls: nil
          )
            @tls = tls || OpenTelemetry::Exporter::OTLP::HTTP::HttpTlsConfig.new(ca_file: certificate_file, key_file: client_key_file, cert_file: client_certificate_file)
            @ssl_verify_mode = ssl_verify_mode
            @endpoint = endpoint
          end
        end
      end
    end
  end
end
