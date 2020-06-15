# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK, 'global_tracer_configurations' do
  let(:sdk) { OpenTelemetry::SDK }
  let(:exporter) { sdk::Trace::Export::InMemorySpanExporter.new }
  let(:span_processor) { sdk::Trace::Export::SimpleSpanProcessor.new(exporter) }
  let(:provider) do
    OpenTelemetry.tracer_provider = sdk::Trace::TracerProvider.new.tap do |provider|
      provider.add_span_processor(span_processor)
    end
  end
  let(:tracer) { provider.tracer(__FILE__, sdk::VERSION) }
  let(:parent_context) { nil }
  let(:finished_spans) { exporter.finished_spans }

  before do
    tracer.in_span('root', with_parent_context: parent_context) do
      tracer.in_span('child1') {}
      tracer.in_span('child2') {}
    end
  end

  describe 'global tracer configurations' do
    describe '#finished_spans' do
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

  describe 'using batch span processor' do
    let(:span_processor) { sdk::Trace::Export::BatchSpanProcessor.new(exporter: exporter) }

    it "doesn't crash" do
      finished_spans
    end
  end

  describe 'using tracestate in extracted span context' do
    let(:mock_tracestate) { 'vendor_key=vendor_value' }
    let(:parent_span_context) { OpenTelemetry::Trace::SpanContext.new(tracestate: mock_tracestate) }
    let(:parent_context) do
      OpenTelemetry::Context.empty.set_value(
        OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key,
        parent_span_context
      )
    end

    describe '#finished_spans' do
      it 'propogates tracestate through span lifecycle into SpanData' do
        finish_span_keys = finished_spans.collect(&:members).flatten.uniq

        _(finish_span_keys).must_include(:tracestate)

        finished_spans.first.tracestate.must_equal(mock_tracestate)
      end
    end
  end
end
