# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter do
  InMemorySpanExporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter
  Span = OpenTelemetry::SDK::Trace::Span

  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILED_NOT_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_NOT_RETRYABLE

  let(:span1)   { Span.new }
  let(:span2)   { Span.new }

  let(:subject) { InMemorySpanExporter.new }

  it 'accepts an Array of Spans as argument to #export' do
    subject.export([span1, span2])

    finished_spans = subject.finished_spans
    finished_spans[0].must_equal span1
    finished_spans[1].must_equal span2
  end

  it 'accepts an Enumerable of Spans as argument to #export' do
    # An anonymous Struct serves as a handy implementor of Enumerable
    enumerable = Struct.new(:span1, :span2).new
    enumerable.span1 = span1
    enumerable.span2 = span2

    subject.export(enumerable)

    finished_spans = subject.finished_spans
    finished_spans[0].must_equal span1
    finished_spans[1].must_equal span2
  end

  it 'freezes the return of #finished_spans' do
    subject.export([span1])
    subject.finished_spans.frozen?.must_equal true
  end

  it 'allows additional calls to #export after #finished_spans' do
    subject.export([span1])
    finished_spans1 = subject.finished_spans

    subject.export([span2])
    finished_spans2 = subject.finished_spans

    finished_spans1.length.must_equal 1
    finished_spans2.length.must_equal 2

    finished_spans1[0].must_equal finished_spans2[0]
  end

  it 'returns success from #export' do
    subject.export([span1]).must_equal SUCCESS
  end

  it 'returns error from #export after #shutdown called' do
    subject.export([span1])
    subject.shutdown

    subject.export([span2]).must_equal FAILED_NOT_RETRYABLE
  end

  it 'returns an empty array from #export after #shutdown called' do
    subject.export([span1])
    subject.shutdown

    subject.finished_spans.length.must_equal 0
  end
end
