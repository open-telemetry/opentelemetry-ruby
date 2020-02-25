#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'rubygems'
require 'bundler/setup'
require 'faraday'
# Require otel-ruby
require 'opentelemetry/sdk'

# Allow setting the host from the ENV
host = ENV.fetch('HTTP_EXAMPLE_HOST', '0.0.0.0')

SDK = OpenTelemetry::SDK
OpenTelemetry.tracer_provider = SDK::Trace::TracerProvider.new

# Configure tracer
exporter = SDK::Trace::Export::ConsoleSpanExporter.new
processor = SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
OpenTelemetry.tracer_provider.add_span_processor(processor)
tracer = OpenTelemetry.tracer_provider.tracer('faraday', 'semver:1.0')
formatter = OpenTelemetry.tracer_provider.http_text_format

connection = Faraday.new("http://#{host}:4567")
url = '/hello'

# For attribute naming, see:
# https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md#http-client

# Span name should be set to URI path value:
tracer.in_span(
  url,
  attributes: {
    'component' => 'http',
    'http.method' => 'GET',
  },
  kind: :client
) do |span|
  response = connection.get(url) do |request|
    # Inject context into request headers
    formatter.inject(span.context, request.headers)
  end

  span.set_attribute('http.url', response.env.url.to_s)
  span.set_attribute('http.status_code', response.status)
  span.set_attribute('http.status_text', response.reason_phrase)
end
