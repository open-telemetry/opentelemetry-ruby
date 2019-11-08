# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../middlewares/tracer_middleware'

module OpenTelemetry
  module Adapters
    module Sinatra
      module Extensions
        module TracerExtension
          # Sinatra hook after extension is registered
          def self.registered(app)
            # Create tracing `render` method
            ::Sinatra::Base.module_eval do
              def render(engine, data, *)
                Sinatra::Adapter.tracer.in_span(
                  'sinatra.render_template',
                  kind: :server,
                  with_parent: Sinatra::Adapter.tracer.current_span
                ) do |span|
                  template_name = data.is_a?(Symbol) ? data : :literal
                  span.set_attribute('sinatra.template_name', template_name.to_s)
                  output = super
                end
              end
            end

            app.use Middlewares::TracerMiddleware
          end
        end
      end
    end
  end
end
