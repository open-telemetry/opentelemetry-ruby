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
          def build_uri(endpoint, path = '', primary_src = '', secondary_src = '', default = nil)
            env_endpoint = OpenTelemetry::Common::Utilities.config_opt(primary_src, secondary_src, default: default) unless endpoint
            endpoint ||= env_endpoint
            raise ArgumentError, "invalid url for OTLPExporter #{endpoint}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)

            if !env_endpoint.nil? && env_endpoint != ENV[primary_src]
              env_endpoint += '/' unless env_endpoint.end_with?('/')
              URI.join(env_endpoint, path)
            else
              URI(endpoint)
            end
          end
        end
      end
    end
  end
end
