# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Link do
  Link = OpenTelemetry::SDK::Trace::Link
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }
  describe '.new' do
    it 'accepts a span_context' do
      link = Link.new(span_context: span_context, attributes: nil)
      link.context.must_equal(span_context)
    end
  end
  describe '.attributes' do
    it 'returns an empty hash by default' do
      link = Link.new(span_context: span_context, attributes: nil)
      link.attributes.must_equal({})
    end
    it 'returns and freezes attributes passed in' do
      attributes = { 'foo' => 'bar', 'bar' => 'baz' }
      link = Link.new(span_context: span_context, attributes: attributes)
      link.attributes.must_equal(attributes)
      link.attributes.must_be(:frozen?)
    end
  end
end
