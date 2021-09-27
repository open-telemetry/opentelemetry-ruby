# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module InstrumentationHelpers
    module HTTP
      # RequestAttributes contains instrumentation helpers for http instrumentation client requests
      module RequestAttributes
        def from_request(method, uri = nil, config = {}, scheme: nil, target: nil, url: nil, hostname: nil, port: nil)
          uri = hide_query_params(uri) if config[:hide_query_params]
          url = hide_url_query_params(url) if config[:hide_query_params]

          {
            'http.method' => method,
            'http.scheme' => scheme || uri&.scheme,
            'http.target' => target || uri&.request_uri,
            'http.url' => url || uri&.to_s,
            'peer.hostname' => hostname || uri&.host,
            'peer.port' => port || uri&.port
          }.compact
        end

        private

        def hide_url_query_params(url)
          return url unless url.is_a?(String)

          query_param_start = url.index("?")

          return url unless query_param_start

          url[0,query_param_start]
        end

        def hide_query_params(uri)
          uri = uri.dup
          uri.query = '' if uri&.query

          uri
        end
      end
    end
  end
end
