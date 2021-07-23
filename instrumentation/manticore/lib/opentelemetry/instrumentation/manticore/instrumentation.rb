# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Manticore
      # The Instrumentation class contains logic to detect and install the Manticore instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        present do
          defined?(::Manticore::Client) && defined?(::Manticore::Response)
        end

        install do |_config|
          require_dependencies
          patch_response
        end

        option :sanitize_headers, default:%w[authorization signature oauth_signature], validate: :array
        option :record_all_response_headers, default: false, validate: :boolean
        option :record_all_request_headers, default: false, validate: :boolean

        private

        def require_dependencies
          require_relative 'util/wrapped_request'
          require_relative 'util/wrapped_response'
          require_relative 'patches/response'
        end

        def patch_response
          ::Manticore::Response.prepend(Patches::Response)
          ::Manticore::Response.class_eval do
            alias_method :call_without_otel_trace!, :call
            alias_method :call, :call_with_otel_trace!
          end
        end
      end
    end
  end
end
