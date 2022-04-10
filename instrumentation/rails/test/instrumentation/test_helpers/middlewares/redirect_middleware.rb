# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class RedirectMiddleware
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    return [307, {}, 'Temporary Redirect'] if should_redirect?(env)

    @app.call(env)
  end

  private

  def should_redirect?(env)
    env['PATH_INFO'] == '/redirection' || env['QUERY_STRING'].include?('redirect_in_middleware')
  end
end
