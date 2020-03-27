# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module ConcurrentRuby
      # The Adapter class contains logic to detect and install the
      # ConcurrentRuby instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Concurrent::Future)
        end

        private

        def require_dependencies
          require_relative 'patches/future'
        end

        def patch
          ::Concurrent::Future.send(:include, Patches::Future)
        end
      end
    end
  end
end
