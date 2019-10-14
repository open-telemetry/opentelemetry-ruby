# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'grape'

require_relative 'tracer_middleware'

class ExampleAPI < Grape::API
  # Integrate with OpenTelemetry:
  use TracerMiddleware

  get '/' do
    'root'
  end

  get 'test' do
    'Test'
  end
end
