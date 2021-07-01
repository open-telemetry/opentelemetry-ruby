# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails::SpanSubscriber do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rails::Instrumentation.instance }
  let(:tracer) { instrumentation.tracer }
  let(:exporter) { EXPORTER }
  let(:last_span) { exporter.finished_spans.last }
  let(:subscriber) do
    OpenTelemetry::Instrumentation::Rails::SpanSubscriber.new(
      name: 'bar.foo',
      tracer: tracer
    )
  end

  before do
    exporter.reset
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install({})
  end

  it 'memoizes the span name' do
    span, = subscriber.start('oh.hai', 'abc', {})
    _(span.name).must_equal('foo bar')
  end

  it 'uses the provided tracer' do
    subscriber = OpenTelemetry::Instrumentation::Rails::SpanSubscriber.new(
      name: 'oh.hai',
      tracer: OpenTelemetry.tracer_provider.tracer('foo')
    )
    span, = subscriber.start('oh.hai', 'abc', {})
    _(span.instrumentation_library.name).must_equal('foo')
  end

  it 'finishes the passed span' do
    span, token = subscriber.start('hai', 'abc', {})
    subscriber.finish('hai', 'abc', __opentelemetry_span: span, __opentelemetry_ctx_token: token)

    # If it's in exporter.finished_spans ... it's finished.
    _(last_span).wont_be_nil
  end

  it 'sets attributes as expected' do
    span, token = subscriber.start('hai', 'abc', {})
    # We only use the finished attributes - could change in the future, perhaps.
    subscriber.finish(
      'hai',
      'abc',
      __opentelemetry_span: span,
      __opentelemetry_ctx_token: token,
      string: 'keys_are_present',
      numeric_is_fine: 1,
      boolean_okay?: true,
      symbols: :are_stringified,
      empty_array_is_okay: [],
      homogeneous_arrays_are_fine: %i[one two],
      heterogeneous_arrays_are_not: [1, false],
      exception: %w[Exception is_not_set_as_attribute],
      exception_object: Exception.new('is_not_set_as_attribute'),
      nil_values_are_rejected: nil,
      complex_values_are_rejected: { foo: :bar }
    )

    _(last_span).wont_be_nil
    _(last_span.attributes['string']).must_equal('keys_are_present')
    _(last_span.attributes['numeric_is_fine']).must_equal(1)
    _(last_span.attributes['boolean_okay?']).must_equal(true)
    _(last_span.attributes['symbols']).must_equal('are_stringified')
    _(last_span.attributes['empty_array_is_okay']).must_equal([])
    _(last_span.attributes['homogeneous_arrays_are_fine']).must_equal(%w[one two])
    _(last_span.attributes.key?('heterogeneous_arrays_are_not')).must_equal(false)
    _(last_span.attributes.key?('exception')).must_equal(false)
    _(last_span.attributes.key?('exception_object')).must_equal(false)
    _(last_span.attributes.key?('nil_values_are_rejected')).must_equal(false)
    _(last_span.attributes.key?('complex_values_are_rejected')).must_equal(false)
  end

  it 'logs an exception_object correctly' do
    span, token = subscriber.start('hai', 'abc', {})
    # We only use the finished attributes - could change in the
    # future, perhaps.
    subscriber.finish(
      'hai',
      'abc',
      __opentelemetry_span: span,
      __opentelemetry_ctx_token: token,
      exception_object: Exception.new('boom')
    )

    status = last_span.status
    _(status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
    _(status.description).must_equal('Unhandled exception of type: Exception')

    event = last_span.events.first
    _(event.name).must_equal('exception')
    _(event.attributes['exception.message']).must_equal('boom')
  end

  describe 'instrumentation option - disallowed_notification_payload_keys' do
    before do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(disallowed_notification_payload_keys: [:foo])
    end

    after do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({})
    end

    it 'does not set disallowed attributes from notification payloads' do
      span, token = subscriber.start('hai', 'abc', {})
      subscriber.finish(
        'hai',
        'abc',
        __opentelemetry_span: span,
        __opentelemetry_ctx_token: token,
        foo: 'bar',
        baz: 'bat'
      )

      _(last_span).wont_be_nil
      _(last_span.attributes.key?('foo')).must_equal(false)
      _(last_span.attributes['baz']).must_equal('bat')
    end
  end

  describe 'instrumentation option - notification_payload_transform' do
    let(:transformer_proc) { ->(v) { v.transform_values { 'optimus prime' } } }

    before do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(notification_payload_transform: transformer_proc)
    end

    after do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install({})
    end

    it 'allows a callable to transform all payload values' do
      span, token = subscriber.start('hai', 'abc', {})
      subscriber.finish(
        'hai',
        'abc',
        __opentelemetry_span: span,
        __opentelemetry_ctx_token: token,
        thing: 'a semi truck'
      )

      _(last_span).wont_be_nil
      _(last_span.attributes['thing']).must_equal('optimus prime')
    end
  end
end
