# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # A ScopeManager provides an API for interfacing with
      # OpenTelemetry Tracers and Spans as OpenTracing objects
      class ScopeManager
        SCOPE_KEY = :__opentelemetry_opentracing_scope__
        MANAGER_KEY = :__opentelemetry_opentracing_scope_manager__
        private_constant :SCOPE_KEY
        private_constant :MANAGER_KEY

        def self.current
          current = Thread.current[MANAGER_KEY]
          unless current
            current = ScopeManager.new
            Thread.current[MANAGER_KEY] = current
          end
          current
        end

        def active
          Thread.current[SCOPE_KEY]
        end

        def active=(scope)
          Thread.current[SCOPE_KEY] = scope
        end

        def activate(span, finish_on_close: true)
          self.active = Scope.new(self, span, finish_on_close)
        end
      end
    end
  end
end
