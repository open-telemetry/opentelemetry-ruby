# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

# setup fake rack application:
builder = Rack::Builder.new
app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['All responses are OK']] }
builder.run app

# demonstrate integration using 'retain_middlware_names' and 'application':
ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack',
        retain_middleware_names: true,
        application: builder,
        record_frontend_span: true
end

# integrate instrumentation explicitly:
builder.use OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware

# demonstrate tracing (span output to console):
puts Rack::MockRequest.new(builder).get('/')
