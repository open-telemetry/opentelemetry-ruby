# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingShim::SpanContextShim do
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }
  let(:span_context_shim) { OpenTelemetry::OpenTracingShim::SpanContextShim.new span_context }
  describe '#trace_id' do
    it 'returns the trace_id of the underlying context' do
      span_context_shim.trace_id.must_equal span_context.trace_id
    end
  end

  describe '#span_id' do
    it 'returns the span_id of the underlying context' do
      span_context_shim.span_id.must_equal span_context.span_id
    end
  end
end
