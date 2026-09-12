# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'

module OpenTelemetry
  module Exporter
    module OTLP
      module Common
        # Contains common utilities used by the otlp exporters
        module Utilities
          extend self

          # Builds a url using the endpoint defined and if not present uses the configured sources
          def build_uri(endpoint, path = '', primary_src = '', secondary_src = 'OTEL_EXPORTER_OTLP_ENDPOINT', default = 'http://localhost:4318/')
            endpoint ||= ENV.fetch(primary_src)
            raise ArgumentError, "invalid url for OTLPExporter #{endpoint} set via #{primary_src}" unless endpoint.nil? || OpenTelemetry::Common::Utilities.valid_url?(endpoint)

            if endpoint.nil?
              endpoint = ENV.fetch(secondary_src, default)
              raise ArgumentError, "invalid url for OTLPExporter #{endpoint} set via #{secondary_src}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)
              endpoint += '/' unless endpoint.end_with?('/')
              URI.join(endpoint, path)
            else
              URI(endpoint)
            end
          end
        end
      end
    end
  end
end
