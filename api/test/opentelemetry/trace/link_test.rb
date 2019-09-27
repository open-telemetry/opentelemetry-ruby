# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Link do
  Link = OpenTelemetry::Trace::Link
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }
  describe '.new' do
    it 'accepts a span_context' do
      link = Link.new(span_context)
      link.context.must_equal(span_context)
    end

    it 'returns a link with the given span context and attributes' do
      link = Link.new(span_context, '1' => 1)
      link.attributes.must_equal('1' => 1)
      link.context.must_equal(span_context)
    end

    it 'returns a link with no attributes by default' do
      link = Link.new(span_context)
      link.attributes.must_equal({})
    end
  end

  describe '.attributes' do
    it 'returns and freezes attributes passed in' do
      attributes = { 'foo' => 'bar', 'bar' => 'baz' }
      link = Link.new(span_context, attributes)
      link.attributes.must_equal(attributes)
      link.attributes.must_be(:frozen?)
    end
  end
end
