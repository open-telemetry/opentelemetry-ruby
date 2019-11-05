# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK, 'global_tracer_configurations' do
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

  def trace_some_operations(tracer)
    tracer.in_span('root') do
      tracer.in_span('child1') do
      end
      tracer.in_span('child2_with_links', links: links) do
      end
    end
  end

  before do
    factory.add_span_processor(span_processor)
  end

  describe 'global tracer configurations' do
    before do
      trace_some_operations(tracer)
    end

    describe '#finished_spans' do
      let(:finished_spans) { exporter.finished_spans }

      it 'has 3' do
        _(finished_spans.size).must_equal(3)
      end

      it 'first span is child1' do
        _(finished_spans.first.name).must_equal('child1')
      end

      it 'are all SpanData' do
        _(finished_spans.collect(&:class).uniq).must_equal([sdk::Trace::SpanData])
      end
    end
  end
end
