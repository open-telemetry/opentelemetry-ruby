# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GoogleApisCore
      # The Instrumentation class contains logic to detect and install the GoogleApisCore instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Google::Apis::Core::HttpCommand)
        end

        private

        def patch
          ::Google::Apis::Core::HttpCommand.prepend(Patches::HttpCommand)
        end

        def require_dependencies
          require_relative 'patches/http_command'
        end
      end
    end
  end
end
