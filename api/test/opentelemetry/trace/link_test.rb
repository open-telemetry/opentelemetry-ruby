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
    it 'accepts a span_context' do
      link = OpenTelemetry::Trace::Link.new(span_context: span_context)
      link.context.must_equal(span_context)
    end
  end
  describe '.attributes' do
    it 'returns an empty hash by default' do
      link = OpenTelemetry::Trace::Link.new(span_context: span_context)
      link.attributes.must_equal({})
    end
    it 'returns and freezes attributes passed in' do
      attributes = { 'foo' => 'bar', 'bar' => 'baz' }.freeze
      link = OpenTelemetry::Trace::Link.new(span_context: span_context,
                                            attributes: attributes)
      link.attributes.must_equal(attributes)
      link.attributes.must_be(:frozen?)
    end
    it 'lazily formats and freezes attributes' do
      attributes_formatted = false
      link = OpenTelemetry::Trace::Link.new(span_context: span_context) do
        attributes_formatted = true
        { 'foo' => 'bar', 'bar' => 'baz' }
      end
      attributes_formatted.must_equal(false)
      link.attributes.must_equal('foo' => 'bar', 'bar' => 'baz')
      link.attributes.must_be(:frozen?)
      attributes_formatted.must_equal(true)
    end
    it 'raises an exception if both attributes and a formatter are passed in' do
      proc do
        OpenTelemetry::Trace::Link.new(span_context: span_context,
                                       attributes: { 'foo' => 'bar' }) do
          { 'bar' => 'baz' }
        end
      end.must_raise(ArgumentError)
    end
    it 'raises an exception if formatter returns invalid attributes' do
      proc do
        link = OpenTelemetry::Trace::Link.new(span_context: span_context) do
          { 'bar' => Object.new }
        end
        link.attributes
      end.must_raise(RuntimeError)
    end
  end
end
