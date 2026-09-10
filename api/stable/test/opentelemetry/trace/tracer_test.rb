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
      OpenTelemetry::Trace.non_recording_span(parent_span_context),
      parent_context: OpenTelemetry::Context.empty
    )
  end

  describe '#in_span' do
    it 'yields the new span' do
      tracer.in_span('wrapper') do |span|
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
    it 'returns an invalid unsampled span' do
      span = tracer.start_root_span('root')
      _(span.context).wont_be :valid?
      _(span.context.trace_flags).wont_be :sampled?
    end
  end

  describe '#start_span' do
    # Specification:
    # The API MUST return a non-recording Span with the SpanContext in the parent Context
    #  (whether explicitly given or implicit current). If the Span in the parent Context
    #  is already non-recording, it SHOULD be returned directly without instantiating a
    #  new Span. If the parent Context contains no Span, an empty non-recording Span MUST
    #  be returned instead (i.e., having a SpanContext with all-zero Span and Trace IDs,
    #  empty Tracestate, and unsampled TraceFlags).

    it 'should return the parent span directly if already not recording' do
      parent_span = OpenTelemetry::Trace::Span.new
      with_parent = OpenTelemetry::Trace.context_with_span(parent_span, parent_context: OpenTelemetry::Context.empty)
      span = tracer.start_span('op', with_parent: with_parent)
      _(span).must_equal(parent_span)
      _(span).wont_be :recording?
    end

    it 'returns a non-recording span with the parent span context if the parent span is recording' do
      parent_span = OpenTelemetry::Trace::Span.new
      span = parent_span.stub(:recording?, true) do
        with_parent = OpenTelemetry::Trace.context_with_span(parent_span, parent_context: OpenTelemetry::Context.empty)
        tracer.start_span('op', with_parent: with_parent)
      end
      _(span).wont_equal(parent_span)
      _(span.context).must_equal(parent_span.context)
      _(span).wont_be :recording?
    end

    it 'returns an invalid unsampled span when no parent is provided' do
      span = tracer.start_span('op', with_parent: OpenTelemetry::Context.empty)
      _(span.context).wont_be :valid?
      _(span.context.trace_flags).wont_be :sampled?
      _(span).wont_be :recording?
    end
  end
end
