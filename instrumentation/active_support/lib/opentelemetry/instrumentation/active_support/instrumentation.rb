# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveSupport
      # The Instrumentation class contains logic to detect and install the ActiveSupport instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
        end

        present do
          # TODO: Replace true with a definition check of the gem being instrumented
          # Example: `defined?(::Rack)`
          true
        end

        private

        def require_dependencies
          require_relative 'span_subscriber'
        end
      end
    end
  end
end
