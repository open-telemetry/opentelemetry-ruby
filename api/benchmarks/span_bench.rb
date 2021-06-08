# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'
require 'opentelemetry/sdk'

OpenTelemetry::SDK.configure
tracer = OpenTelemetry.tracer_provider.tracer('bench')
span = tracer.start_root_span('bench')

attributes = {
  'component' => 'rack',
  'span.kind' => 'server',
  'http.method' => 'GET',
  'http.url' => 'blogs/index'
}

Benchmark.ipsa do |x|
  x.report 'name=' do
    span.name = 'new_name'
  end

  x.report 'set_attribute' do
    span.set_attribute('k', 'v')
  end

  x.report 'add_event' do
    span.add_event('test event', attributes: attributes)
  end

  x.compare!
end
