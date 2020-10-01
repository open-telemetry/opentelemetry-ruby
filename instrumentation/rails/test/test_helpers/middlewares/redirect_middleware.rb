# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class RedirectMiddleware
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    [307, {}, 'Temporary Redirect']
  end
end
