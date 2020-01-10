# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
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
      Minitest::Mock.new.expect(:finish, nil).expect(:nil?, false)
    end
  end

  let(:invalid_span) { OpenTelemetry::Trace::Span::INVALID }
  let(:invalid_span_context) { OpenTelemetry::Trace::SpanContext::INVALID }
  let(:invalid_parent_context) do
    OpenTelemetry::Context.empty.set_value(
      OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key,
      invalid_span_context
    )
  end
  let(:tracer) { Tracer.new }
  let(:context_key)
  let(:parent_span_context) { OpenTelemetry::Trace::SpanContext.new }
  let(:parent_context) do
    OpenTelemetry::Context.empty.set_value(
      OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key,
      parent_span_context
    )
  end

  describe '#current_span' do
    let(:current_span) { tracer.start_span('current') }

    it 'returns an invalid span by default' do
      _(tracer.current_span).must_equal(invalid_span)
    end

    it 'returns the current span' do
      wrapper_span = tracer.start_span('wrapper')

      tracer.with_span(wrapper_span) do
        _(tracer.current_span).must_equal(wrapper_span)
      end
    end
  end

  describe '#active_span_context' do
    let(:current_span) { tracer.start_span('current') }

    it 'returns an invalid span context by default' do
      _(tracer.active_span_context).must_equal(invalid_span_context)
    end

    it 'returns the span context from the current context by default' do
      wrapper_span = tracer.start_span('wrapper')

      tracer.with_span(wrapper_span) do
        _(tracer.active_span_context).must_equal(wrapper_span.context)
      end
    end

    it 'returns span context from implicit and explicit contexts' do
      wrapper_span = tracer.start_span('wrapper')
      wrapper_ctx = nil

      tracer.with_span(wrapper_span) do
        wrapper_ctx = Context.current
      end

      inner_span = tracer.start_span('inner')

      tracer.with_span(inner_span) do
        _(tracer.active_span_context).must_equal(inner_span.context)
        _(tracer.active_span_context(wrapper_ctx)).must_equal(wrapper_span.context)
      end
    end
  end

  describe '#in_span' do
    let(:parent) { tracer.start_span('parent') }

    it 'yields the new span' do
      tracer.in_span('wrapper') do |span|
        _(span).wont_equal(invalid_span)
        _(tracer.current_span).must_equal(span)
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

    it 'yields a span with the same context as the parent' do
      tracer.in_span('op', with_parent: parent) do |span|
        _(span.context).must_be :valid?
        _(span.context).must_equal(parent.context)
      end
    end

    it 'yields a span with the parent context' do
      tracer.in_span('op', with_parent_context: parent_context) do |span|
        _(span.context).must_be :valid?
        _(span.context).must_equal(parent_span_context)
      end
    end
  end

  describe '#with_span' do
    it 'yields the passed in span' do
      wrapper_span = tracer.start_span('wrapper')

      tracer.with_span(wrapper_span) do |span|
        _(span).must_equal(wrapper_span)
      end
    end

    it 'should reactive the span after the block' do
      outer = tracer.start_span('outer')
      inner = tracer.start_span('inner')

      tracer.with_span(outer) do
        _(tracer.current_span).must_equal(outer)

        tracer.with_span(inner) do
          _(tracer.current_span).must_equal(inner)
        end

        _(tracer.current_span).must_equal(outer)
      end
    end

    it 'should reactivate the span context after the block' do
      outer = tracer.start_span('outer')
      inner = tracer.start_span('inner')

      tracer.with_span(outer) do
        _(tracer.active_span_context).must_equal(outer.context)

        tracer.with_span(inner) do
          _(tracer.active_span_context).must_equal(inner.context)
        end

        _(tracer.active_span_context).must_equal(outer.context)
      end
    end
  end

  describe '#start_root_span' do
    it 'returns a valid span' do
      span = tracer.start_root_span('root')
      _(span.context).must_be :valid?
    end
  end

  describe '#start_span' do
    let(:parent) { tracer.start_span('parent') }

    it 'returns a valid span with the parent context' do
      span = tracer.start_span('op', with_parent_context: parent_context)
      _(span.context).must_be :valid?
      _(span.context).must_equal(parent_span_context)
    end

    it 'returns a span with a new context by default' do
      span = tracer.start_span('op')
      _(span.context).must_be :valid?
      _(span.context).wont_equal(tracer.current_span.context)
    end

    it 'returns a span with the same context as the parent' do
      span = tracer.start_span('op', with_parent: parent)
      _(span.context).must_be :valid?
      _(span.context).must_equal(parent.context)
    end

    it 'returns a span with a new context when passed an invalid context' do
      span = tracer.start_span('op', with_parent_context: invalid_parent_context)
      _(span.context).must_be :valid?
      _(span.context).wont_equal(invalid_span_context)
    end
  end
end
