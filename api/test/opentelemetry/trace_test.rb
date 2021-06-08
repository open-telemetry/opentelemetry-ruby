# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace do
  let(:tracer) { Tracer.new }
  let(:invalid_span) { OpenTelemetry::Trace::Span::INVALID }

  describe '#current_span' do
    let(:current_span) { tracer.start_span('current') }

    it 'returns an invalid span by default' do
      _(OpenTelemetry::Trace.current_span).must_equal(invalid_span)
    end

    it 'returns the current span' do
      wrapper_span = tracer.start_span('wrapper')

      OpenTelemetry::Trace.with_span(wrapper_span) do
        _(OpenTelemetry::Trace.current_span).must_equal(wrapper_span)
      end
    end

    it 'returns the current span from the provided context' do
      span = OpenTelemetry::Trace.non_recording_span(OpenTelemetry::Trace::SpanContext.new)
      context = OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
      _(OpenTelemetry::Trace.current_span).wont_equal(span)
      _(OpenTelemetry::Trace.current_span(context)).must_equal(span)
    end
  end

  describe '#with_span' do
    it 'yields the passed in span' do
      wrapper_span = tracer.start_span('wrapper')

      OpenTelemetry::Trace.with_span(wrapper_span) do |span|
        _(span).must_equal(wrapper_span)
      end
    end

    it 'yields context containing span' do
      wrapper_span = tracer.start_span('wrapper')

      OpenTelemetry::Trace.with_span(wrapper_span) do |span, context|
        _(context).must_equal(OpenTelemetry::Context.current)
        _(OpenTelemetry::Trace.current_span).must_equal(span)
      end
    end

    it 'should reactive the span after the block' do
      outer = tracer.start_span('outer')
      inner = tracer.start_span('inner')

      OpenTelemetry::Trace.with_span(outer) do
        _(OpenTelemetry::Trace.current_span).must_equal(outer)

        OpenTelemetry::Trace.with_span(inner) do
          _(OpenTelemetry::Trace.current_span).must_equal(inner)
        end

        _(OpenTelemetry::Trace.current_span).must_equal(outer)
      end
    end
  end

  describe '#context_with_span' do
    it 'returns a context containing span' do
      span = tracer.start_span('test')
      ctx = OpenTelemetry::Trace.context_with_span(span)
      _(OpenTelemetry::Trace.current_span(ctx)).must_equal(span)
    end

    it 'returns a context containing span' do
      parent_ctx = OpenTelemetry::Context.empty.set_value('foo', 'bar')
      span = tracer.start_span('test')
      ctx = OpenTelemetry::Trace.context_with_span(span, parent_context: parent_ctx)
      _(OpenTelemetry::Trace.current_span(ctx)).must_equal(span)
      _(ctx.value('foo')).must_equal('bar')
    end
  end
end
