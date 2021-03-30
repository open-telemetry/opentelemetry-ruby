# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RestClient
      # The Instrumentation class contains logic to detect and install the RestClient
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_request
        end

        present do
          defined?(::RestClient)
        end

        option :peer_service, default: nil, validate: :string

        private

        def require_dependencies
          require_relative 'patches/request'
        end

        def patch_request
          ::RestClient::Request.prepend(Patches::Request)
        end
      end
    end
  end
end
