#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

ENV['OTEL_CONFIG_FILE'] ||= File.join(__dir__, 'otel-config-console.yaml')

require 'bundler/setup'
require 'net/http'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-all'
require 'opentelemetry_otelconfig'

sdk = OpenTelemetry::OtelConfig.configure
OpenTelemetry.tracer_provider = sdk.tracer_provider
OpenTelemetry.propagation = sdk.propagator if sdk&.propagator

tracer = OpenTelemetry.tracer_provider.tracer('otelconfig-example', '1.0.0')

tracer.in_span('process-order', attributes: { 'order.id' => 'ORD-001', 'order.items' => 3 }) do |span|
  span.add_event('validation-started')

  # Simulate nested work in a child span
  tracer.in_span('validate-inventory', attributes: { 'warehouse' => 'us-west-2' }) do |child|
    sleep(0.01) # simulate I/O
    child.set_attribute('inventory.available', true)
    child.add_event('inventory-checked', attributes: { 'sku' => 'WIDGET-42', 'qty' => 10 })
  end

  span.add_event('validation-complete')
  span.set_attribute('order.total_usd', 49.99)
end

OpenTelemetry.tracer_provider.force_flush(timeout: 30)

SITES = [
  { name: 'google.ca',  uri: URI('https://www.google.ca') },
  { name: 'github.com', uri: URI('https://github.com') }
].freeze

tracer.in_span('http-requests') do
  SITES.each do |site|
    tracer.in_span("GET #{site[:name]}",
                   attributes: {
                     'http.method' => 'GET',
                     'http.url' => site[:uri].to_s,
                     'net.peer.name' => site[:name]
                   }) do |span|
      response = Net::HTTP.get_response(site[:uri])
      span.set_attribute('http.status_code', response.code.to_i)
      if response['content-length']
        span.set_attribute('http.response_content_length',
                           response['content-length'].to_i)
      end
    end
  end
end

OpenTelemetry.tracer_provider.shutdown
