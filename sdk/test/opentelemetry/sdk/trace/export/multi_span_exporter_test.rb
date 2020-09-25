# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::MultiSpanExporter do
  export = OpenTelemetry::SDK::Trace::Export

  let(:spans)               { [OpenTelemetry::Trace::Span.new, OpenTelemetry::Trace::Span.new] }

  let(:mock_span_exporter)  { Minitest::Mock.new }
  let(:mock_span_exporter2) { Minitest::Mock.new }

  let(:exporter) do
    export::MultiSpanExporter.new([mock_span_exporter])
  end

  let(:exporter_multi) do
    export::MultiSpanExporter.new(
      [mock_span_exporter, mock_span_exporter2]
    )
  end

  let(:exporter_empty) do
    export::MultiSpanExporter.new([])
  end

  it 'accepts an Array of Spans as arg to #export and forwards them' do
    mock_span_exporter.expect(:export, export::SUCCESS) { |a| a.to_a == spans }

    _(exporter.export(spans)).must_equal export::SUCCESS
    mock_span_exporter.verify
  end

  it 'accepts an Enumerable of Spans as arg to #export and forwards them' do
    # An anonymous Struct serves as a handy implementor of Enumerable
    enumerable = Struct.new(:span0, :span1).new(spans[0], spans[1])

    mock_span_exporter.expect(:export, export::SUCCESS) { |a| a.to_a == spans }

    _(exporter.export(enumerable)).must_equal export::SUCCESS
    mock_span_exporter.verify
  end

  it 'forwards spans from #export to multiple exporters' do
    mock_span_exporter.expect(:export, export::SUCCESS) { |a| a.to_a == spans }
    mock_span_exporter2.expect(:export, export::SUCCESS) { |a| a.to_a == spans }

    _(exporter_multi.export(spans)).must_equal export::SUCCESS
    mock_span_exporter.verify
    mock_span_exporter2.verify
  end

  it 'returns an error from #export if one exporter fails' do
    mock_span_exporter.expect(:export, export::SUCCESS) { |a| a.to_a == spans }
    mock_span_exporter2.expect(:export, export::FAILURE) { |a| a.to_a == spans }

    _(exporter_multi.export(spans)).must_equal export::FAILURE
    mock_span_exporter.verify
    mock_span_exporter2.verify
  end

  it 'synthesizes an error if an exporter raises an exception' do
    def mock_span_exporter.export(_, timeout: nil)
      raise ArgumentError
    end

    logger_mock = Minitest::Mock.new
    logger_mock.expect :warn, nil, [/ArgumentError/]
    OpenTelemetry.stub :logger, logger_mock do
      _(exporter.export(spans)).must_equal export::FAILURE
    end

    logger_mock.verify
  end

  it 'forwards a #shutdown call to all exporters' do
    mock_span_exporter.expect :shutdown, nil, [{ timeout: nil }]
    mock_span_exporter2.expect :shutdown, nil, [{ timeout: nil }]

    exporter_multi.shutdown
    mock_span_exporter.verify
    mock_span_exporter2.verify
  end

  it 'returns success on #export with empty exporter list' do
    _(exporter_empty.export(spans)).must_equal export::SUCCESS
  end

  it 'accepts calls to #shutdown with empty exporter list' do
    exporter_empty.shutdown
  end
end
