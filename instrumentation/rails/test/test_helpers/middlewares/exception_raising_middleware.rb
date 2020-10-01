# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExceptionRaisingMiddleware
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    raise 'the roof'
  end
end
