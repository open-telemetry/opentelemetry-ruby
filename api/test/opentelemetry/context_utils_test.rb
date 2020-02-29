# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context do
  Context = OpenTelemetry::Context
  ContextUtils = OpenTelemetry::ContextUtils

  let(:current_span_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.current_span_key
  end
  let(:span_context_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key
  end
  let(:correlations_key) do
    OpenTelemetry::CorrelationContext::Propagation::ContextKeys.correlation_context_key
  end
  let(:correlations) { { 'foo' => 'bar' } }
  let(:context_with_correlations) do
    Context.empty.set_value(correlations_key, correlations)
  end
  let(:span) { OpenTelemetry::Trace::Span.new }
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }

  describe '.span_from' do
    it 'reads the current span from context' do
      ctx = Context.empty.set_value(current_span_key, span)
      ContextUtils.span_from(ctx).must_equal(span)
    end

    it 'returns nil if there is not a current span' do
      ContextUtils.span_from(Context.empty).must_be_nil
    end
  end

  describe '.set_span' do
    it 'returns a new context containing span' do
      ctx = ContextUtils.set_span(span)
      ctx[current_span_key].must_equal(span)
    end

    it 'returns a new context containing span with parent context' do
      parent_ctx = context_with_correlations

      parent_ctx[current_span_key].wont_equal(span)
      parent_ctx[correlations_key].must_equal(correlations)

      ctx = ContextUtils.set_span(span, parent: parent_ctx)

      ctx[current_span_key].must_equal(span)
      ctx[correlations_key].must_equal(correlations)
    end
  end

  describe '.set_span_context' do
    it 'returns a new context containing span context' do
      ctx = ContextUtils.set_span_context(span_context)
      ctx[span_context_key].must_equal(span_context)
    end

    it 'returns a new context containing span context with parent context' do
      parent_ctx = context_with_correlations

      parent_ctx[span_context_key].wont_equal(span)
      parent_ctx[correlations_key].must_equal(correlations)

      ctx = ContextUtils.set_span_context(span_context, parent: parent_ctx)

      ctx[span_context_key].must_equal(span_context)
      ctx[correlations_key].must_equal(correlations)
    end
  end
end
