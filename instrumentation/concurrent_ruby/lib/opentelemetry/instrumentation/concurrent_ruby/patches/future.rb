# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../context_composite_executor_service'

module OpenTelemetry
  module Instrumentation
    module ConcurrentRuby
      module Patches
        # Concurrent::Future patch for instrumentation
        module Future
          def self.included(base)
            base.class_eval do
              alias_method :ns_initialize_without_otel, :ns_initialize
              remove_method(:ns_initialize)

              def ns_initialize(value, opts)
                ns_initialize_without_otel(value, opts)

                @executor = ContextCompositeExecutorService.new(@executor)
              end
            end
          end
        end
      end
    end
  end
end
