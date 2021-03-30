# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Ethon
      # The Instrumentation class contains logic to detect and install the Ethon
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          add_patches
        end

        present do
          defined?(::Ethon::Easy)
        end

        option :peer_service, default: nil, validate: :string

        private

        def require_dependencies
          require_relative 'patches/easy'
          require_relative 'patches/multi'
        end

        def add_patches
          ::Ethon::Easy.prepend(Patches::Easy)
          ::Ethon::Multi.prepend(Patches::Multi)
        end
      end
    end
  end
end
