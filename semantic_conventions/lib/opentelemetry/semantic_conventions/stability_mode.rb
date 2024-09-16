# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    # The StabilityMode class provides constants and methods for semantic conventions stability
    class StabilityMode
      OTEL_SEMCONV_STABILITY_OPT_IN = 'OTEL_SEMCONV_STABILITY_OPT_IN'

      DEFAULT = 'default' # emit old conventions ONLY
      HTTP = 'http' # emit stable HTTP and networking conventions ONLY
      HTTP_DUP = 'http/dup' # emit both old and stable HTTP and networking conventions      

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
          # Users can pass in comma delimited string for opt-in options
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

      def set_http_method(result, request_method)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD, request_method) if report_old?(HTTP)
        set_string_attribute(result, HTTP_REQUEST_METHOD, request_method) if report_new?(HTTP)
      end
      
      def set_http_status_code(result, code)
        set_int_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE, code) if report_old?(HTTP)
        set_int_attribute(result, HTTP_RESPONSE_STATUS_CODE, code) if report_new?(HTTP)
      end
      
      def set_http_url(result, url)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_URL, url) if report_old?(HTTP)
        set_string_attribute(result, URL_FULL, url) if report_new?(HTTP)
      end
      
      def set_http_scheme(result, scheme)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_SCHEME, scheme) if report_old?(HTTP)
        set_string_attribute(result, URL_SCHEME, scheme) if report_new?(HTTP)
      end
      
      # Client
      
      def set_http_net_peer_name_client(result, peer_name)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME, peer_name) if report_old?(HTTP)
        set_string_attribute(result, SERVER_ADDRESS, peer_name) if report_new?(HTTP)
      end
      
      def set_http_peer_port_client(result, port)
        set_int_attribute(result, OpenTelemetry::SemanticConventions::Trace::NET_PEER_PORT, port) if report_old?(HTTP)
        set_int_attribute(result, SERVER_PORT, port) if report_new?(HTTP)
      end

      def set_http_target(result, path, query)
        set_string_attribute(result, OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET, path) if report_old?(HTTP)
        return unless report_new?(HTTP)

        set_string_attribute(result, URL_PATH, path)
        set_string_attribute(result, URL_QUERY, query)
      end
    end
  end
end