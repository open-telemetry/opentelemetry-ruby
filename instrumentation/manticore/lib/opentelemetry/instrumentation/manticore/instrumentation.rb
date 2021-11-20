# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Manticore
      # The Instrumentation class contains logic to detect dependencies and install the Manticore instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        present do
          (defined?(::Manticore::Response) && RUBY_PLATFORM == 'java')
        end

        install do |_config|
          require_dependencies
          patch
        end

        # Optional list of headers client may want to record as part of the span
        option "record_request_headers_list", default: [], validate: :array
        option "record_response_headers_list", default: [], validate: :array

        private

        def require_dependencies
          require_relative 'util/wrapped_request'
          require_relative 'patches/response'
        end

        def patch
          ::Manticore::Response.prepend(Patches::Response)
        end
      end
    end
  end
end
