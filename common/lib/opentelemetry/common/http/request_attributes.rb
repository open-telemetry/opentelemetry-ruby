# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    module HTTP
      # RequestAttributes contains common helpers for setting http client attributes in spans
      module RequestAttributes
        extend self

        def from_request(request_method, uri, config = {})
          uri = hide_query_params(uri) if config[:hide_query_params]

          {
            'http.method' => request_method,
            'http.scheme' => uri.scheme,
            'http.target' => uri.request_uri,
            'http.url' => uri.to_s,
            'peer.hostname' => uri.host,
            'peer.port' => uri.port
          }.compact
        end

        def hide_query_params(uri)
          uri = uri.dup
          uri.query = '' if uri.query

          uri
        end
      end
    end
  end
end