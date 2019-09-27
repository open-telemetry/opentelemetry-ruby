# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

def stub_span_builder(sampled: false)
  ctx = OpenTelemetry::Trace::SpanContext.new
  span = OpenTelemetry::Trace::Span.new(span_context: ctx)
  def span.to_span_data; end
  if sampled
    def span.recording_events?
      true
    end
  end
  span
end

describe OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor do
  export = OpenTelemetry::SDK::Trace::Export

  let :mock_span_exporter do
    mock = Minitest::Mock.new
    def mock.nil?
      false
    end

    mock
  end

  let(:stub_span_unsampled) { stub_span_builder(sampled: false) }
  let(:stub_span_sampled)   { stub_span_builder(sampled: true) }
  let(:processor) { export::SimpleSpanProcessor.new(mock_span_exporter) }

  it 'requires a span_exporter to be passed to #initialize' do
    proc do
      export::SimpleSpanProcessor.new(nil)
    end.must_raise ArgumentError
  end

  it 'accepts calls to #on_start' do
    processor.on_start(stub_span_sampled)
  end

  it 'forwards sampled spans from #on_finish' do
    mock_span_exporter.expect :export, export::SUCCESS, [Array]

    processor.on_start(stub_span_sampled)
    processor.on_finish(stub_span_sampled)
    mock_span_exporter.verify
  end

  it 'ignores unsampled spans in #on_finish' do
    processor.on_start(stub_span_unsampled)
    processor.on_finish(stub_span_unsampled)
    mock_span_exporter.verify
  end

  it 'calls #to_span_data on sampled spans in #on_finish' do
    processor_noop = export::SimpleSpanProcessor.new(
      export::NoopSpanExporter.new
    )

    mock_span = Minitest::Mock.new
    mock_span.expect :recording_events?, true
    mock_span.expect :to_span_data, nil

    processor_noop.on_start(mock_span)
    processor_noop.on_finish(mock_span)
    mock_span.verify
  end

  it 'catches and logs exporter exceptions in #on_finish' do
    raising_exporter = export::NoopSpanExporter.new

    def raising_exporter.export(_)
      raise ArgumentError
    end

    processor_with_raising_exporter = export::SimpleSpanProcessor.new(
      raising_exporter
    )

    processor_with_raising_exporter.on_start(stub_span_sampled)

    logger_mock = Minitest::Mock.new
    logger_mock.expect :error, nil, [/ArgumentError/]
    OpenTelemetry.stub :logger, logger_mock do
      processor_with_raising_exporter.on_finish(stub_span_sampled)
    end

    logger_mock.verify
  end

  it 'forwards calls to #shutdown to the exporter' do
    mock_span_exporter.expect :shutdown, nil

    processor.shutdown
    mock_span_exporter.verify
  end
end
