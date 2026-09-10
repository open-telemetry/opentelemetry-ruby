# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Link do
  Link = OpenTelemetry::Trace::Link
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }
  describe '.new' do
    it 'accepts a span_context' do
      link = Link.new(span_context)
      _(link.span_context).must_equal(span_context)
    end

    it 'returns a link with the given span context and attributes' do
      link = Link.new(span_context, '1' => 1)
      _(link.attributes).must_equal('1' => 1)
      _(link.span_context).must_equal(span_context)
    end

    it 'returns a link with no attributes by default' do
      link = Link.new(span_context)
      _(link.attributes).must_equal({})
    end

    it 'allows array-valued attributes' do
      attributes = { 'foo' => [1, 2, 3] }
      link = Link.new(span_context, attributes)
      _(link.attributes).must_equal(attributes)
    end
  end

  describe '.attributes' do
    it 'returns and freezes attributes passed in' do
      attributes = { 'foo' => 'bar', 'bar' => 'baz' }
      link = Link.new(span_context, attributes)
      _(link.attributes).must_equal(attributes)
      _(link.attributes).must_be(:frozen?)
    end
  end
end
