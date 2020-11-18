# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails::Instrumentation do
  it 'adds the tracing middleware' do
    _(DEFAULT_RAILS_APP.config.middleware).must_include OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware
  end
end
