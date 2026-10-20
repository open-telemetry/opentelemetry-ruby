#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'rubygems'
require 'bundler/setup'
require 'faraday'
# Require otel-ruby
require 'opentelemetry/sdk'
require 'opentelemetry/semconv/http'
require 'opentelemetry/semconv/url'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

# Allow setting the host from the ENV
host = ENV.fetch('HTTP_EXAMPLE_HOST', '0.0.0.0')

# configure SDK with defaults
OpenTelemetry::SDK.configure

# Configure tracer
tracer = OpenTelemetry.tracer_provider.tracer('faraday', '1.0')

connection = Faraday.new("http://#{host}:4567")
url = '/hello'

# For attribute naming, see:
# https://github.com/open-telemetry/semantic-conventions/blob/main/docs/http/http-spans.md#http-client-span

# Span name should be set to URI path value:
tracer.in_span(
  url,
  attributes: {
    OpenTelemetry::SemConv::URL::URL_SCHEME => 'http',
    OpenTelemetry::SemConv::HTTP::HTTP_REQUEST_METHOD => 'GET',
  },
  kind: :client
) do |span|
  response = connection.get(url) do |request|
    # Inject context into request headers
    OpenTelemetry.propagation.inject(request.headers)
  end

  span.set_attribute(OpenTelemetry::SemConv::URL::URL_FULL, response.env.url.to_s)
  span.set_attribute(OpenTelemetry::SemConv::HTTP::HTTP_RESPONSE_STATUS_CODE, response.status)
end
