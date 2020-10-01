# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/rails/instrumentation'

describe OpenTelemetry::Instrumentation::Rails::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rails::Instrumentation.instance }

  before do
    # Simulate a fresh install
    instrumentation.instance_variable_set('@installed', false)
    instrumentation.install({})

    # Initialize rails app so railties are called
    app.initialize!
  end

  it 'adds the tracing middleware' do
    _(app.config.middleware).must_include OpenTelemetry::Instrumentation::Rails::Middlewares::TracerMiddleware
  end

  private

  def app
    @app ||= Class.new(::Rails::Application) do
      config.eager_load = false # Ensure we don't see this Rails warning when testing
      config.logger = Logger.new('/dev/null') # Prevent tests from creating log/*.log
      config.secret_key_base = ('a' * 30)
    end
  end
end
