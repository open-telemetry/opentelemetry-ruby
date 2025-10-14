#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
# Require otel-ruby
require 'opentelemetry/sdk'
require 'opentelemetry/semconv/http'
require 'opentelemetry/semconv/url'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

# configure SDK with defaults
OpenTelemetry::SDK.configure

# Rack middleware to extract span context, create child span, and add
# attributes/events to the span
class OpenTelemetryMiddleware
  def initialize(app)
    @app = app
    @tracer = OpenTelemetry.tracer_provider.tracer('sinatra', '1.0')
  end

  def call(env)
    # Extract context from request headers
    context = OpenTelemetry.propagation.extract(
      env,
      getter: OpenTelemetry::Common::Propagation.rack_env_getter
    )

    status, headers, response_body = 200, {}, ''

    # Span name SHOULD be set to route:
    span_name = env['PATH_INFO']

    # For attribute naming, see
    # https://github.com/open-telemetry/semantic-conventions/blob/main/docs/http/http-spans.md#http-server

    # Activate the extracted context
    OpenTelemetry::Context.with_current(context) do
      # Span kind MUST be `:server` for a HTTP server span
      @tracer.in_span(
        span_name,
        attributes: {
          OpenTelemetry::SemConv::URL::URL_SCHEME => 'http',
          OpenTelemetry::SemConv::HTTP::HTTP_REQUEST_METHOD => env['REQUEST_METHOD'],
          OpenTelemetry::SemConv::HTTP::HTTP_ROUTE => env['PATH_INFO'],
          OpenTelemetry::SemConv::URL::URL_PATH => env['REQUEST_URI'],
        },
        kind: :server
      ) do |span|
        # Run application stack
        status, headers, response_body = @app.call(env)

        span.set_attribute(OpenTelemetry::SemConv::HTTP::HTTP_RESPONSE_STATUS_CODE, status)
      end
    end

    [status, headers, response_body]
  end
end

class App < Sinatra::Base
  set :bind, '0.0.0.0'
  use OpenTelemetryMiddleware

  get '/hello' do
    'Hello World!'
  end

  run! if app_file == $0
end
