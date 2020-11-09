# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class Application < Rails::Application; end
require 'action_controller/railtie'
require 'test_helpers/middlewares'
require 'test_helpers/controllers'
require 'test_helpers/routes'

module AppConfig
  extend self

  def initialize_app(use_exceptions_app: false, add_middlewares: true)
    new_app = Application.new
    new_app.config.secret_key_base = 'secret_key_base'

    # Ensure we don't see this Rails warning when testing
    new_app.config.eager_load = false

    # Prevent tests from creating log/*.log
    new_app.config.logger = Logger.new('/dev/null')

    case Rails.version
    when /^6\.0/
      apply_rails_6_0_configs(new_app)
    end

    add_exceptions_app(new_app) if use_exceptions_app
    add_middlewares(new_app)

    new_app.initialize!

    draw_routes(new_app)

    new_app
  end

  private

  def add_exceptions_app(application)
    application.config.exceptions_app = lambda do |env|
      ExceptionsController.action(:show).call(env)
    end
  end

  def add_middlewares(application)
    application.middleware.insert_after(
      ActionDispatch::DebugExceptions,
      ExceptionRaisingMiddleware
    )

    application.middleware.insert_after(
      ActionDispatch::DebugExceptions,
      RedirectMiddleware
    )
  end

  def apply_rails_6_0_configs(application)
    # Required in Rails 6
    application.config.hosts << 'example.org'
    # Creates a lot of deprecation warnings on subsequent app initializations if not explicitly set.
    application.config.action_view.finalize_compiled_template_methods = ActionView::Railtie::NULL_OPTION
  end
end
