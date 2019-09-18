# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Export::NoopSpanExporter do
  export = OpenTelemetry::SDK::Trace::Export

  let(:spans)   { [OpenTelemetry::Trace::Span.new, OpenTelemetry::Trace::Span.new] }
  let(:subject) { export::NoopSpanExporter.new }

  it 'accepts an Array of Spans as arg to #export and succeeds' do
    subject.export(spans).must_equal export::SUCCESS
  end

  it 'accepts an Enumerable of Spans as arg to #export and succeeds' do
    # An anonymous Struct serves as a handy implementor of Enumerable
    enumerable = Struct.new(:span0, :span1).new
    enumerable.span0 = spans[0]
    enumerable.span1 = spans[1]

    subject.export(enumerable).must_equal export::SUCCESS
  end

  it 'accepts calls to #shutdown' do
    subject.shutdown
  end
end
