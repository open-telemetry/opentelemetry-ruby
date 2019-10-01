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
        KEY = :__opentelemetry_opentracing_scope__
        private_constant :KEY

        def active
          Thread.current[KEY]
        end

        def active=(scope)
          Thread.current[KEY] = scope
        end

        def activate(span, finish_on_close: true)
          self.active = Scope.new(self, span, finish_on_close)
        end
      end
    end
  end
end
