# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails::Instrumentation do
  it 'adds the tracing middleware' do
    _(::Rails.application.config.middleware).must_include OpenTelemetry::Instrumentation::Rails::Middlewares::TracerMiddleware
  end
end
