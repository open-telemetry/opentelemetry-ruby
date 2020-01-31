# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Ethon
      # The Adapter class contains logic to detect and install the Ethon
      # instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_config|
          require_dependencies
          add_patches
        end

        present do
          defined?(::Ethon::Easy)
        end

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
