# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK, 'API_trace' do
  let(:span_processor) { sdk::Trace::Export::SimpleSpanProcessor.new(exporter) }
  let(:exporter) { sdk::Trace::Export::InMemorySpanExporter.new }
  let(:tracer) { factory.tracer(__FILE__, sdk::VERSION) }
  let(:factory) { OpenTelemetry.tracer_factory = sdk::Trace::TracerFactory.new }
  let(:sdk) { OpenTelemetry::SDK }
  let(:links) do
    Array.new(3) do
      OpenTelemetry::Trace::Link.new(
        OpenTelemetry::Trace::SpanContext.new,
        attributes
      )
    end
  end
  let(:attributes) do
    { 'component' => 'rack',
      'span.kind' => 'server',
      'http.method' => 'GET',
      'http.url' => 'blogs/index' }
  end
  let(:remote_span_context) do
    OpenTelemetry::Trace::SpanContext.new(remote: true)
  end

  def trace_some_operations(tracer)
    tracer.in_span('root') do
      tracer.in_span('child1') do
      end
      tracer.in_span('child2_with_links', links: links) do
      end
    end
  end

  def trace_child_of_remote_spans(tracer)
    tracer.start_span('remote', with_parent_context: remote_span_context) do
      tracer.in_span('child1') do
      end
    end
  end

  before do
    factory.add_span_processor(span_processor)
  end

  describe 'tracing operations' do
    before do
      trace_some_operations(tracer)
    end

    it 'traces root spans' do
      tracer.in_span('root') do |root_span|
        _(root_span.name).must_equal 'root'
        _(root_span.to_span_data.child_count).must_equal 2
      end
    end

    it 'traces child-of-local spans' do
      skip 'TODO'
    end

    it 'traces without links' do
      tracer.in_span('child1') do |span|
        _(span.links.size).must_equal 0
      end
    end

    it 'traces with links' do
      tracer.in_span('child2_with_links') do |span|
        _(span.links.size).must_equal 3
      end
    end
  end

  describe 'child-of-remote spans' do
    before { trace_child_of_remote_spans(tracer) }

    it 'traces spans' do
      tracer.in_span('remote') do |span|
        _(span.name).must_equal 'remote'
        _(span.context.remote?).must_equal true
      end
    end
  end
end
