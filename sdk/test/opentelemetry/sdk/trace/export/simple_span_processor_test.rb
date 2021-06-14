# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

def stub_span_builder(recording: false)
  trace_flags = recording ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
  ctx = OpenTelemetry::Trace::SpanContext.new(trace_flags: trace_flags)
  span = OpenTelemetry::Trace.non_recording_span(ctx)
  def span.to_span_data; end

  span.define_singleton_method(:recording?) { recording }
  span
end

describe OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor do
  export = OpenTelemetry::SDK::Trace::Export

  let :mock_span_exporter do
    mock = Minitest::Mock.new
    def mock.nil?
      false
    end

    def mock.export(spans, timeout: nil); end

    def mock.shutdown(timeout: nil); end

    def mock.force_flush(timeout: nil); end

    mock
  end

  let(:stub_span_unrecorded) { stub_span_builder(recording: false) }
  let(:stub_span_recorded)   { stub_span_builder(recording: true) }
  let(:parent_context) { OpenTelemetry::Context.empty }
  let(:processor) { export::SimpleSpanProcessor.new(mock_span_exporter) }

  it 'accepts calls to #on_start' do
    processor.on_start(stub_span_recorded, parent_context)
  end

  it 'forwards calls to #force_flush to the exporter' do
    mock_span_exporter.instance_eval { undef :force_flush }
    mock_span_exporter.expect :force_flush, nil, [{ timeout: nil }]

    processor.force_flush
    mock_span_exporter.verify
  end

  it 'forwards recorded spans from #on_finish' do
    mock_span_exporter.instance_eval { undef :export }
    mock_span_exporter.expect :export, export::SUCCESS, [Array]

    processor.on_start(stub_span_recorded, parent_context)
    processor.on_finish(stub_span_recorded)
    mock_span_exporter.verify
  end

  it 'ignores unrecorded spans in #on_finish' do
    processor.on_start(stub_span_unrecorded, parent_context)
    processor.on_finish(stub_span_unrecorded)
    mock_span_exporter.verify
  end

  it 'calls #to_span_data on sampled spans in #on_finish' do
    processor_noop = export::SimpleSpanProcessor.new(
      export::SpanExporter.new
    )

    mock_trace_flags = Minitest::Mock.new
    mock_trace_flags.expect :sampled?, true
    mock_span_context = Minitest::Mock.new
    mock_span_context.expect :trace_flags, mock_trace_flags
    mock_span = Minitest::Mock.new
    mock_span.expect :context, mock_span_context
    mock_span.expect :to_span_data, nil

    processor_noop.on_start(mock_span, parent_context)
    processor_noop.on_finish(mock_span)
    mock_span.verify
  end

  it 'catches and logs exporter exceptions in #on_finish' do
    raising_exporter = export::SpanExporter.new

    def raising_exporter.export(_)
      raise ArgumentError
    end

    processor_with_raising_exporter = export::SimpleSpanProcessor.new(
      raising_exporter
    )

    processor_with_raising_exporter.on_start(stub_span_recorded, parent_context)

    logger_mock = Minitest::Mock.new
    logger_mock.expect :error, nil, [/ArgumentError/]
    OpenTelemetry.stub :logger, logger_mock do
      processor_with_raising_exporter.on_finish(stub_span_recorded)
    end

    logger_mock.verify
  end

  it 'forwards calls to #shutdown to the exporter' do
    mock_span_exporter.instance_eval { undef :shutdown }
    mock_span_exporter.expect :shutdown, nil, [{ timeout: nil }]

    processor.shutdown
    mock_span_exporter.verify
  end

  it 'raises if exporter is nil' do
    _(-> { export::SimpleSpanProcessor.new(nil) }).must_raise(ArgumentError)
  end

  it 'raises if exporter is not an exporter' do
    _(-> { export::SimpleSpanProcessor.new(exporter: export::SpanExporter.new) }).must_raise(ArgumentError)
  end
end
