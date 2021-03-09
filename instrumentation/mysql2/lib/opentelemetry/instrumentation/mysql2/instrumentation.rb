# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mysql2
      # The Instrumentation class contains logic to detect and install the Mysql2
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Mysql2)
        end

        option :peer_service, default: nil, validate: :string
        option :enable_sql_obfuscation, default: false, validate: :boolean

        private

        def require_dependencies
          require_relative 'patches/client'
        end

        def patch_client
          ::Mysql2::Client.prepend(Patches::Client)
        end
      end
    end
  end
end
