# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Mysql2
      # The Adapter class contains logic to detect and install the Mysql2
      # instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Mysql2)
        end

        private

        def require_dependencies
          require_relative 'utils'
          require_relative 'patches/client'
        end

        def patch_client
          ::Mysql2::Client.prepend(Patches::Client)
        end
      end
    end
  end
end
