# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ipsa'
require 'opentelemetry'

tracer = OpenTelemetry::Trace::Tracer.new

parent_span = tracer.start_span('parent')
parent_context = OpenTelemetry::Trace.context_with_span(parent_span)

attributes = {
  'component' => 'rack',
  'span.kind' => 'server',
  'http.method' => 'GET',
  'http.url' => 'blogs/index'
}

links = Array.new(3) do
  OpenTelemetry::Trace::Link.new(
    OpenTelemetry::Trace::SpanContext.new,
    attributes
  )
end

Benchmark.ipsa do |x|
  x.report 'start span' do
    span = tracer.start_span('test_span')
    span.finish
  end

  x.report 'start span with parent context' do
    span = tracer.start_span('test_span', with_parent: parent_context)
    span.finish
  end

  x.report 'start span with attributes' do
    span = tracer.start_span('test_span', attributes: attributes)
    span.finish
  end

  x.report 'start span with links' do
    span = tracer.start_span('test_span', links: links)
    span.finish
  end

  x.compare!
end
