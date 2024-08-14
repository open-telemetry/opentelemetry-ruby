# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter do
  export = OpenTelemetry::SDK::Trace::Export

  let(:span_data1)   { OpenTelemetry::SDK::Trace::SpanData.new({ name: 'name1' }) }
  let(:span_data2)   { OpenTelemetry::SDK::Trace::SpanData.new({ name: 'name2' }) }

  let(:exporter) { OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new }

  it 'accepts an Array of SpanDatas as argument to #export' do
    exporter.export([span_data1, span_data2])

    finished_spans = exporter.finished_spans
    _(finished_spans[0]).must_equal span_data1
    _(finished_spans[1]).must_equal span_data2
  end

  it 'accepts an Enumerable of SpanDatas as argument to #export' do
    # An anonymous Struct serves as a handy implementer of Enumerable
    enumerable = Struct.new(:span_data1, :span_data2).new
    enumerable.span_data1 = span_data1
    enumerable.span_data2 = span_data2

    exporter.export(enumerable)

    finished_spans = exporter.finished_spans
    _(finished_spans[0]).must_equal span_data1
    _(finished_spans[1]).must_equal span_data2
  end

  it 'freezes the return of #finished_spans' do
    exporter.export([span_data1])
    _(exporter.finished_spans).must_be :frozen?
  end

  it 'allows additional calls to #export after #finished_spans' do
    exporter.export([span_data1])
    finished_spans1 = exporter.finished_spans

    exporter.export([span_data2])
    finished_spans2 = exporter.finished_spans

    _(finished_spans1.length).must_equal 1
    _(finished_spans2.length).must_equal 2

    _(finished_spans1[0]).must_equal finished_spans2[0]
  end

  it 'returns success from #export' do
    _(exporter.export([span_data1])).must_equal export::SUCCESS
  end

  it 'returns error from #export after #shutdown called' do
    exporter.export([span_data1])
    exporter.shutdown

    _(exporter.export([span_data2])).must_equal export::FAILURE
  end

  it 'returns an empty array from #export after #shutdown called' do
    exporter.export([span_data1])
    exporter.shutdown

    _(exporter.finished_spans.length).must_equal 0
  end

  it 'records nothing if #recording is false' do
    exporter.recording = false
    exporter.export([span_data1])
    _(exporter.finished_spans.length).must_equal 0

    # In this test, we're generally recording all the time - restore that state.
    exporter.recording = true
  end
end
