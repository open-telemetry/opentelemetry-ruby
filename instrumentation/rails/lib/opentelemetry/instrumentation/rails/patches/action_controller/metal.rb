# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      module Patches
        module ActionController
          # Module to prepend to ActionController::Metal for instrumentation
          module Metal
            def dispatch(name, request, response)
              rack_span = OpenTelemetry::Instrumentation::Rack.current_span
              rack_span.name = "#{self.class.name}##{name}" if rack_span.context.valid? && !request.env['action_dispatch.exception']
              super(name, request, response)
            end
          end
        end
      end
    end
  end
end
