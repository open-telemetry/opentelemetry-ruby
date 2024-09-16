# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    # The `StabilityMode` class allows controls which semantic conventions are emitted.
    #
    # For more information on semantic conventions stability, refer to 
    # {https://opentelemetry.io/docs/specs/otel/versioning-and-stability/#semantic-conventions-stability OpenTelemetry documentation}. 
    #
    # ## Configuration
    # The `StabilityMode` class is relies on the `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable, a comma-delimited string of stability modes to opt into. 
    # 
    # Currently, `OTEL_SEMCONV_STABILITY_OPT_IN` only supports {https://opentelemetry.io/docs/specs/semconv/http/ semantic conventions for HTTP}. 
    # The values defined for `OTEL_SEMCONV_STABILITY_OPT_IN` are:
    #   - `http`: Emit stable HTTP and networking conventions ONLY
    #   - `http/dup`: Emit both old and stable HTTP and networking conventions
    #   - `default`: Emit old conventions ONLY
    #
    # If no `OTEL_SEMCONV_STABILITY_OPT_IN` is set, the `default` behavior is used. `http/dup` has higher precedence than `http`` in case both values are present.
    # 
    # Example usage:
    # ```ruby
    # stability_mode = OpenTelemetry::SemanticConventions::StabilityMode.new
    # stability_mode.set_http_method(result, 'GET')
    # stability_mode.set_http_status_code(result, 200)
    # stability_mode.set_http_url(result, 'https://example.com')
    # ```
    class StabilityMode
      OTEL_SEMCONV_STABILITY_OPT_IN = 'OTEL_SEMCONV_STABILITY_OPT_IN'

      DEFAULT = 'default'
      HTTP = 'http'
      HTTP_DUP = 'http/dup'

      # These constants will be pulled in from elsehwere once semvconv stability PR merged
      # https://github.com/open-telemetry/opentelemetry-ruby/pull/1651
      HTTP_REQUEST_METHOD = 'http.request.method'
      HTTP_RESPONSE_STATUS_CODE = 'http.response.status_code'
      URL_SCHEME = 'url.scheme'
      URL_PATH = 'url.path'
      URL_QUERY = 'url.query'
      URL_FULL = 'url.full'
      SERVER_ADDRESS = 'server.address'
      SERVER_PORT = 'server.port'

      attr_accessor :initialized, :lock, :otel_semconv_stability_signal_mapping

      def initialize
        @lock = Mutex.new
        @otel_semconv_stability_signal_mapping = {}

        @lock.synchronize do
          opt_in = ENV.fetch('OTEL_SEMCONV_STABILITY_OPT_IN', nil)
          opt_in_list = opt_in.split(',').map(&:strip) if opt_in
          http_set_sability_mode(opt_in_list) if opt_in_list
        end
      end

      def http_set_sability_mode(opt_in_list)
        return unless opt_in_list.include?(HTTP) || opt_in_list.include?(HTTP_DUP)

        http_opt_in = DEFAULT
        if opt_in_list.include?(HTTP_DUP) # http/dup takes priority over http
          http_opt_in = HTTP_DUP
        elsif opt_in_list.include?(HTTP)
          http_opt_in = HTTP
        end
        otel_semconv_stability_signal_mapping['http'] = http_opt_in
      end

      def report_new?(opt_in_mode)
        otel_semconv_stability_signal_mapping[opt_in_mode] != DEFAULT
      end

      def report_old?(opt_in_mode)
        otel_semconv_stability_signal_mapping[opt_in_mode] != HTTP
      end

      def set_string_attribute(result, key, value)
        result[key] = String(value) if value
      end

      def set_int_attribute(result, key, value)
        result[key] = Integer(value) if value
      end

      # Sets the HTTP method attribute in the result hash.
      #
      # @param result [Hash] The result hash.
      # @param request_method [String] The HTTP request method.
      def set_http_method(result, request_method)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD, request_method) if report_old?(HTTP)
        set_string_attribute(result, HTTP_REQUEST_METHOD, request_method) if report_new?(HTTP)
      end

      # Sets the HTTP status code attribute in the result hash.
      #
      # @param result [Hash] The result hash.
      # @param code [Integer] The HTTP status code.
      def set_http_status_code(result, code)
        set_int_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, code) if report_old?(HTTP)
        set_int_attribute(result, HTTP_RESPONSE_STATUS_CODE, code) if report_new?(HTTP)
      end

      # Sets the HTTP URL attribute in the result hash.
      #
      # @param result [Hash] The result hash.
      # @param url [String] The HTTP URL.
      def set_http_url(result, url)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_URL, url) if report_old?(HTTP)
        set_string_attribute(result, URL_FULL, url) if report_new?(HTTP)
      end

      # Sets the HTTP scheme attribute in the result hash.
      #
      # @param result [Hash] The result hash.
      # @param scheme [String] The HTTP scheme.
      def set_http_scheme(result, scheme)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME, scheme) if report_old?(HTTP)
        set_string_attribute(result, URL_SCHEME, scheme) if report_new?(HTTP)
      end

      # Sets the server address attribute in the result hash for client requests.
      #
      # @param result [Hash] The result hash.
      # @param peer_name [String] The server address.
      def set_http_net_peer_name_client(result, peer_name)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME, peer_name) if report_old?(HTTP)
        set_string_attribute(result, SERVER_ADDRESS, peer_name) if report_new?(HTTP)
      end

      # Sets the server port attribute in the result hash for client requests.
      #
      # @param result [Hash] The result hash.
      # @param port [Integer] The server port.
      def set_http_peer_port_client(result, port)
        set_int_attribute(result, OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT, port) if report_old?(HTTP)
        set_int_attribute(result, SERVER_PORT, port) if report_new?(HTTP)
      end

      # Sets the HTTP target attribute in the result hash.
      #
      # @param result [Hash] The result hash.
      # @param path [String] The URL path.
      # @param query [String] The URL query.
      def set_http_target(result, path, query)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET, path) if report_old?(HTTP)
        return unless report_new?(HTTP)

        set_string_attribute(result, URL_PATH, path)
        set_string_attribute(result, URL_QUERY, query)
      end
    end
  end
end