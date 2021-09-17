# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ConcurrentRuby
      # The Instrumentation class contains logic to detect and install the
      # ConcurrentRuby instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Concurrent::RubyExecutorService) || defined?(::Concurrent::JavaExecutorService)
        end

        private

        def require_dependencies
          require_relative 'patches/executor_service'
        end

        def patch
          if ::Concurrent.on_jruby?
            ::Concurrent::JavaExecutorService.prepend Patches::ExecutorService
          else
            ::Concurrent::RubyExecutorService.prepend Patches::ExecutorService
          end
        end
      end
    end
  end
end
