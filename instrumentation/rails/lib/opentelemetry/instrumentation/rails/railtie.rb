# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      # The Instrumentation class contains logic to detect and install the Rails
      # instrumentation, while this Railtie is used to conventionally instrument
      # the Rails application through its initialization hooks
      class Railtie < ::Rails::Railtie
        initializer 'opentelemetry.before_initialize' do |app|
          app.middleware.insert_after(
            ActionDispatch::RequestId,
            OpenTelemetry::Instrumentation::Rails::Middlewares::TracerMiddleware
          )

          # TODO: Check for exceptions app
          # Rails.application.config.exceptions_app or
          # it defaults to https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/public_exceptions.rb
        end

        private

        def config
          Instrumentation.instance.config
        end
      end
    end
  end
end
