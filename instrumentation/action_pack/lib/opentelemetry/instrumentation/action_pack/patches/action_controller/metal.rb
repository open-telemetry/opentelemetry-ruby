# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Patches
        module ActionController
          # Module to prepend to ActionController::Metal for instrumentation
          module Metal
            def dispatch(name, request, response)
              rack_span = OpenTelemetry::Instrumentation::Rack.current_span
              rack_span.name = "#{self.class.name}##{name}" if rack_span.context.valid? && !request.env['action_dispatch.exception']

              add_rails_route(rack_span, request) if instrumentation_config[:enable_recognize_route]
              super(name, request, response)
            end

            private

            def add_rails_route(rack_span, request)
              ::Rails.application.routes.router.recognize(request) do |route, _params|
                rack_span.set_attribute('http.route', route.path.spec.to_s)
              end
            end

            def instrumentation_config
              ActionPack::Instrumentation.instance.config
            end
          end
        end
      end
    end
  end
end
