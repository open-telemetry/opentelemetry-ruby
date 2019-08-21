# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Link do
  let(:span_context) do
    OpenTelemetry::Trace::SpanContext.new(trace_id: 123,
                                          span_id: 456,
                                          trace_options: 0x0)
  end
  describe '.new' do
    it 'has a span_context' do
      link = OpenTelemetry::Trace::Link.new(span_context: span_context)
      link.span_context.must_equal(span_context)
    end
    it 'has empty attributes by default' do
      link = OpenTelemetry::Trace::Link.new(span_context: span_context)
      link.attributes.must_equal({})
    end
    it 'reflects attributes passed in' do
      attributes = { 'foo' => 'bar', 'bar' => 'baz' }.freeze
      link = OpenTelemetry::Trace::Link.new(span_context: span_context,
                                            attributes: attributes)
      link.attributes.must_equal(attributes)
    end
  end
end
