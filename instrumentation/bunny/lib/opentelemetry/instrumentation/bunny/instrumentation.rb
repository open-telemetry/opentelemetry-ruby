# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      # The Instrumentation class contains logic to detect and install the
      # bunny instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_patches
          patch
        end

        present do
          defined?(::Bunny)
        end

        private

        def require_patches
          require_relative 'patch_helpers'
          require_relative 'patches/channel'
          require_relative 'patches/consumer'
          require_relative 'patches/queue'
        end

        def patch
          ::Bunny::Channel.prepend(Patches::Channel)
          ::Bunny::Consumer.prepend(Patches::Consumer)
          ::Bunny::Queue.prepend(Patches::Queue)
        end
      end
    end
  end
end
