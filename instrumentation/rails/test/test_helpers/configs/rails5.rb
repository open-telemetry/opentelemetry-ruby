# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module Rails5
  class Application < Rails::Application
    config.eager_load = false # Ensure we don't see this Rails warning when testing
    config.logger = Logger.new('/dev/null') # Prevent tests from creating log/*.log
    config.secret_key_base = 'secret_key_base'
  end
end

def build_app(use_exceptions_controller: false)
  require 'action_controller/railtie'
  require 'test_helpers/middlewares'

  new_app = ::Rails5::Application.new
  new_app.config.secret_key_base = 'secret_key_base'

  # Ensure we don't see this Rails warning when testing
  new_app.config.eager_load = false

  # Prevent tests from creating log/*.log
  new_app.config.logger = Logger.new('/dev/null')

  if use_exceptions_controller
    new_app.config.exceptions_app = lambda do |env|
      ExceptionsController.action(:show).call(env)
    end
  end

  new_app.middleware.insert_after(
    ActionDispatch::DebugExceptions,
    ExceptionRaisingMiddleware
  )

  new_app.middleware.insert_after(
    ActionDispatch::DebugExceptions,
    RedirectMiddleware
  )

  new_app.initialize!

  require 'test_helpers/routes'
  draw_routes(new_app)

  require 'test_helpers/controllers'

  new_app
end
