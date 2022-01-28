# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Dalli
      # The Instrumentation class contains logic to detect and install the Dalli
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          add_patches
        end

        present do
          defined?(::Dalli)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :include, validate: ->(opt) { %I[omit obfuscate include].include?(opt) }

        private

        def require_dependencies
          require_relative 'utils'
          require_relative 'patches/server'
        end

        def add_patches
          if Gem::Version.new(::Dalli::VERSION) < Gem::Version.new('3.0.0')
            ::Dalli::Server.prepend(Patches::Server)
          else
            ::Dalli::Protocol::Binary.prepend(Patches::Server)
          end
        end
      end
    end
  end
end
