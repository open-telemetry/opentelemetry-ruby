# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'
require 'opentelemetry'

span = OpenTelemetry::Trace::Span.new

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
