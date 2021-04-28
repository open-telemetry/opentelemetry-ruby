# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Tracer do
  Propagation = OpenTelemetry::Trace::Propagation
  Tracer = OpenTelemetry::Trace::Tracer

  # Tracer to verify expectation that `Span#finish` is called
  class TestInSpanFinishTracer < Tracer
    # Override `start_span` to return mock span
    def start_span(*)
      Minitest::Mock.new.expect(:finish, nil)
    end
  end

  let(:invalid_span) { OpenTelemetry::Trace::Span::INVALID }
  let(:invalid_span_context) { OpenTelemetry::Trace::SpanContext::INVALID }
  let(:invalid_parent_context) do
    OpenTelemetry::Trace.context_with_span(
      invalid_span,
      parent_context: OpenTelemetry::Context.empty
    )
  end
  let(:tracer) { Tracer.new }
  let(:context_key)
  let(:parent_span_context) { OpenTelemetry::Trace::SpanContext.new }
  let(:parent_context) do
    OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace::Span.new(span_context: parent_span_context),
      parent_context: OpenTelemetry::Context.empty
    )
  end

  describe '#in_span' do
    it 'yields the new span' do
      tracer.in_span('wrapper') do |span|
        _(span).wont_equal(invalid_span)
        _(OpenTelemetry::Trace.current_span).must_equal(span)
      end
    end

    it 'yields context containing span' do
      tracer.in_span('wrapper') do |span, context|
        _(context).must_equal(OpenTelemetry::Context.current)
        _(OpenTelemetry::Trace.current_span(context)).must_equal(span)
      end
    end

    it 'returns the result of the block' do
      result = tracer.in_span('wrapper') { 'my-result' }
      _(result).must_equal('my-result')
    end

    it 'finishes the new span at the end of the block' do
      finish_tracer = TestInSpanFinishTracer.new
      mock_span = nil
      finish_tracer.in_span('wrapper') { |span| mock_span = span }
      mock_span.verify
    end
  end

  describe '#start_root_span' do
    it 'returns a valid span' do
      span = tracer.start_root_span('root')
      _(span.context).must_be :valid?
    end
  end

  describe '#start_span' do
    it 'returns a valid span with the parent context' do
      span = tracer.start_span('op', with_parent: parent_context)
      _(span.context).must_be :valid?
      _(span.context).must_equal(parent_span_context)
    end

    it 'returns a span with a new context by default' do
      span = tracer.start_span('op')
      _(span.context).must_be :valid?
      _(span.context).wont_equal(OpenTelemetry::Trace.current_span.context)
    end

    it 'returns a span with a new context when passed an invalid context' do
      span = tracer.start_span('op', with_parent: invalid_parent_context)
      _(span.context).must_be :valid?
      _(span.context).wont_equal(invalid_span_context)
    end
  end
end
