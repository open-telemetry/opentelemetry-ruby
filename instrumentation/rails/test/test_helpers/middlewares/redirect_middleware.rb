# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class RedirectMiddleware
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    return [307, {}, 'Temporary Redirect'] if env['PATH_INFO'] == '/redirection'

    @app.call(env)
  end
end
