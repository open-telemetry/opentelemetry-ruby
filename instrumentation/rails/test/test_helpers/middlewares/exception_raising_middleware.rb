# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExceptionRaisingMiddleware
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    raise 'a little hell' if should_raise?(env)

    @app.call(env)
  end

  private

  def should_raise?(env)
    env['PATH_INFO'] == '/exception' || env['QUERY_STRING'].include?('raise_in_middleware')
  end
end
