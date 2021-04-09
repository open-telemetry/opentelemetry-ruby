# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation, while this Railtie is used to conventionally instrument
      # the Rails application through its initialization hooks
      class Railtie < ::Rails::Railtie
        config.before_initialize do |app|
          OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install({})

          app.middleware.insert_after(
            0,
            OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
          )
        end
      end
    end
  end
end
