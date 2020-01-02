# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The instrumentation Registry contains information about instrumentation
    # adapters available and facilitates their installation and configuration.
    class Registry
      def initialize
        @lock = Mutex.new
        @adapters = []
      end

      def register(adapter)
        @lock.synchronize do
          @adapters << adapter
        end
      end

      def lookup(adapter_name)
        @lock.synchronize do
          @adapters.detect { |a| a.instance.adapter_name == adapter_name }
                   &.instance
        end
      end
    end
  end
end
