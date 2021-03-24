# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module HTTP
      # The Instrumentation class contains logic to detect and install the Http instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::HTTP)
        end

        def patch
          ::HTTP::Client.prepend(Patches::Client)
          ::HTTP::Connection.prepend(Patches::Connection)
        end

        def require_dependencies
          require_relative 'patches/client'
          require_relative 'patches/connection'
        end
      end
    end
  end
end
