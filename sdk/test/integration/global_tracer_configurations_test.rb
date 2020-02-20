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
  let(:finished_spans) { exporter.finished_spans }

  before do
    tracer.in_span('root') do
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
end
