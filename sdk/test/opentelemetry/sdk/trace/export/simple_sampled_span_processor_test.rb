# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

def stub_span_builder(sampled: false)
  ctx = OpenTelemetry::Trace::SpanContext.new(
    trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(sampled ? 1 : 0)
  )
  span = OpenTelemetry::Trace::Span.new(span_context: ctx)
  def span.to_span_data; end

  span
end

describe OpenTelemetry::SDK::Trace::Export::SimpleSampledSpanProcessor do
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
  let(:subject) { export::SimpleSampledSpanProcessor.new(mock_span_exporter) }

  it 'requires a span_exporter to be passed to #initialize' do
    proc do
      export::SimpleSampledSpanProcessor.new(nil)
    end.must_raise ArgumentError
  end

  it 'accepts calls to #on_start' do
    subject.on_start(stub_span_sampled)
  end

  it 'forwards sampled spans from #on_end' do
    mock_span_exporter.expect :export, export::SUCCESS, [Array]

    subject.on_start(stub_span_sampled)
    subject.on_end(stub_span_sampled)
    mock_span_exporter.verify
  end

  it 'ignores unsampled spans in #on_end' do
    subject.on_start(stub_span_unsampled)
    subject.on_end(stub_span_unsampled)
    mock_span_exporter.verify
  end

  it 'calls #to_span_data on sampled spans in #on_end' do
    subject_noop = export::SimpleSampledSpanProcessor.new(
      export::NoopSpanExporter.new
    )

    mock_span = Minitest::Mock.new
    mock_span.expect :context, stub_span_sampled.context
    mock_span.expect :to_span_data, nil

    subject_noop.on_start(mock_span)
    subject_noop.on_end(mock_span)
    mock_span.verify
  end

  it 'catches and logs exporter exceptions in #on_end' do
    raising_exporter = export::NoopSpanExporter.new

    def raising_exporter.export(_)
      raise ArgumentError
    end

    subject_with_raising_exporter = export::SimpleSampledSpanProcessor.new(
      raising_exporter
    )

    subject_with_raising_exporter.on_start(stub_span_sampled)

    logger_mock = Minitest::Mock.new
    logger_mock.expect :error, nil, [/ArgumentError/]
    OpenTelemetry.stub :logger, logger_mock do
      subject_with_raising_exporter.on_end(stub_span_sampled)
    end

    logger_mock.verify
  end

  it 'forwards calls to #shutdown to the exporter' do
    mock_span_exporter.expect :shutdown, nil

    subject.shutdown
    mock_span_exporter.verify
  end
end
