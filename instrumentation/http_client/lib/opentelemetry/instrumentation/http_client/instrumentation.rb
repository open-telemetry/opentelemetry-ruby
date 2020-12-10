# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module HttpClient
      # The Instrumentation class contains logic to detect and install the HttpClient instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::HTTPClient)
        end

        private

        def patch
          ::HTTPClient.prepend(Patches::Client)
          ::HTTPClient::Session.prepend(Patches::Session)
        end

        def require_dependencies
          require_relative 'patches/client'
          require_relative 'patches/session'
        end
      end
    end
  end
end
