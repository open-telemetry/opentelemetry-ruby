# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

# setup fake rack application:
builder = Rack::Builder.new
app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['All responses are OK']] }
builder.run app

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Rack', retain_middleware_names: true,
                                         application: builder,
                                         record_frontend_span: true
end

# demonstrate tracing (span output to console):
puts Rack::MockRequest.new(builder).get('/')
