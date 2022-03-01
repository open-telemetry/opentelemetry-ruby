# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    module HTTP
      # RequestAttributes contains instrumentation helpers for http instrumentation client requests
      module RequestAttributes
        QUERY_PARAM_START_KEY = '?'
        def from_request(method:, config: {}, uri: nil, scheme: nil, target: nil, url: nil, hostname: nil, port: nil)
          {
            OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => method,
            OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME => scheme || uri&.scheme,
            OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET => hide_query_params(target || uri&.request_uri, config),
            OpenTelemetry::SemanticConventions::Trace::HTTP_URL => hide_query_params(url || uri&.to_s, config),
            OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => hostname || uri&.host,
            OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT => port || uri&.port
          }.merge!(OpenTelemetry::Common::HTTP::ClientContext.attributes).compact
        end

        private

        def hide_query_params(url_or_path, config)
          return url_or_path unless config.key?(:hide_query_params) && config[:hide_query_params]

          query_param_start = url_or_path.index(QUERY_PARAM_START_KEY)

          return url_or_path unless query_param_start

          url_or_path[0, query_param_start + 1]
        end
      end
    end
  end
end