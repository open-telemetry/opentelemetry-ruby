# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'concurrent/executor/executor_service'
require 'forwardable'

module OpenTelemetry
  module Instrumentation
    module ConcurrentRuby
      # Wraps existing executor to carry over trace context
      class ContextCompositeExecutorService
        extend Forwardable
        include Concurrent::ExecutorService

        attr_accessor :composited_executor

        def initialize(composited_executor)
          @composited_executor = composited_executor
        end

        # post method runs the task within composited executor
        # in a different thread
        def post(*args, &task)
          context = OpenTelemetry::Context.current

          @composited_executor.post(*args) do
            OpenTelemetry::Context.with_current(context) do
              yield
            end
          end
        end

        delegate %i[can_overflow? serialized?] => :composited_executor
      end
    end
  end
end
