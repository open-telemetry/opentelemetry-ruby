# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      module Patches
        module ActionController
          # Module to prepend to ActionController::Metal for instrumentation
          module Metal
            THREAD_KEY = :__opentelemetry_rack_span__

            def dispatch(name, request, response)
              rack_span = Thread.current[THREAD_KEY]
              rack_span.name = "#{self.class.name}##{name}" if rack_span && !request.env['action_dispatch.exception']
              super(name, request, response)
            end
          end
        end
      end
    end
  end
end
