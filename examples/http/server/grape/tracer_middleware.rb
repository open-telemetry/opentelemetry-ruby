# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'

require_relative '../../../exporters/console'

class TracerMiddleware < Grape::Middleware::Base

  SDK = OpenTelemetry::SDK

  def call(env)
    # see: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md#http-server

    # span name SHOULD be set to route:
    span_name = env['grape.routing_args'][:route_info].path
    # if route cannot be determined, it MUST be set to path value:
    # span_name = env['PATH_INFO']

    # """For a HTTP server span, SpanKind MUST be Server"""
    tracer.in_span(span_name, kind: OpenTelemetry::Trace::SpanKind::SERVER) do |span|
      span.add_event(name: 'handle request')
      span.set_attribute('component', 'http') # required
      span.set_attribute('http.method', env['REQUEST_METHOD']) # required
      span.set_attribute('http.route', span_name) # not required
      span.set_attribute('http.url', env['REQUEST_URI']) # not required

      dup.call!(env).tap do |response|
        span.set_attribute('http.status_code', response.status) # not required
        span.set_attribute('http.status_text', Rack::Utils::HTTP_STATUS_CODES[response.status]) # not required

        # allow output to flush via exporter:
        span.finish
      end
    end
  end

  private

  def tracer
    # named tracer should be the library name
    @tracer ||= tracer_factory.tracer('grape', 'semver:1.0').tap do |t|
      t.add_span_processor(processor)
    end
  end

  def tracer_factory
    @tracer_factory ||= SDK::Trace::TracerFactory.new
  end

  def processor
    @processor ||= SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
  end

  def exporter
    @exporter ||= Examples::Exporters::Console.new
  end
end
