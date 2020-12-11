# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        # The Instrumentation class contains logic to detect and install the Net::HTTP
        # instrumentation
        class Instrumentation < OpenTelemetry::Instrumentation::Base
          install do |_config|
            require_dependencies
            patch
          end

          present do
            defined?(::Net::HTTP)
          end

          private

          def require_dependencies
            require_relative 'patches/instrumentation'
          end

          def patch
            ::Net::HTTP.prepend(Patches::Instrumentation)
          end
        end
      end
    end
  end
end
