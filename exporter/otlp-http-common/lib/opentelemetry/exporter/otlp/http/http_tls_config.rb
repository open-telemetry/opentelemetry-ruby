# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # HttpTlsConfig is a configuration class for TLS settings used in the OTLP HTTP exporter.
        class HttpTlsConfig
          attr_reader :ca_file,
                      :key_file,
                      :cert_file

          def initialize(
            ca_file: nil,
            key_file: nil,
            cert_file: nil
          )
            @ca_file = ca_file
            @key_file = key_file
            @cert_file = cert_file
          end
        end
      end
    end
  end
end
