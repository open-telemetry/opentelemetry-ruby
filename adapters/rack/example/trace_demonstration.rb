# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Rack'
end

# setup fake rack application:
builder = Rack::Builder.app do
  # integration should be automatic in web frameworks (like rails),
  # but for a plain Rack application, enable it in your config.ru, e.g.,
  use OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware

  app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['All responses are OK']] }
  run app
end

# demonstrate tracing (span output to console):
puts Rack::MockRequest.new(builder).get('/')
