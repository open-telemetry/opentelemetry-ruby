# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-sdk'

describe OpenTelemetry::Propagator::Jaeger::TextMapInjector do
  let(:injector) { OpenTelemetry::Propagator::Jaeger::TextMapInjector.new }
  let(:identity_key) { 'uber-trace-id' }

  before do
    OpenTelemetry::SDK::Configurator.new.configure
  end

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )
      carrier = {}
      injector.inject(carrier, context)
      trace_span_identity_value = carrier[identity_key]
      trace_id, span_id, parent_span_id, flags = trace_span_identity_value.split(/:/)
      _(trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_id).must_equal('e457b5a2e4d86bd1')
      _(parent_span_id).must_equal('0')
      _(flags).must_equal('1')
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT
      )
      carrier = {}
      injector.inject(carrier, context)
      trace_span_identity_value = carrier[identity_key]
      trace_id, span_id, parent_span_id, flags = trace_span_identity_value.split(/:/)
      _(trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_id).must_equal('e457b5a2e4d86bd1')
      _(parent_span_id).must_equal('0')
      _(flags).must_equal('0')
    end

    it 'injects debug flag when present' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED,
        jaeger_debug: true
      )
      carrier = {}
      injector.inject(carrier, context)
      trace_span_identity_value = carrier[identity_key]
      trace_id, span_id, parent_span_id, flags = trace_span_identity_value.split(/:/)
      _(trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_id).must_equal('e457b5a2e4d86bd1')
      _(parent_span_id).must_equal('0')
      _(flags).must_equal('3')
    end

    it 'injects baggage' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1'
      )
      context = OpenTelemetry.baggage.build(context: context) do |baggage|
        baggage.set_entry('key1', 'value1')
        baggage.set_entry('key2', 'value2')
      end
      carrier = {}
      injector.inject(carrier, context)
      _(carrier['uberctx-key1']).must_equal('value1')
      _(carrier['uberctx-key2']).must_equal('value2')
    end

    it 'URL-encodes baggage.entries before injecting' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1'
      )
      context = OpenTelemetry.baggage.build(context: context) do |baggage|
        baggage.set_entry('key1', 'value 1 / blah')
      end
      carrier = {}
      injector.inject(carrier, context)
      _(carrier['uberctx-key1']).must_equal('value+1+%2F+blah')
    end

    it 'injects to rack keys' do
      rack_env_setter = Object.new
      def rack_env_setter.set(carrier, key, value)
        rack_key = 'HTTP_' + key
        rack_key.tr!('-', '_')
        rack_key.upcase!
        carrier[rack_key] = value
      end
      rack_injector = OpenTelemetry::Propagator::Jaeger::TextMapInjector.new(
        rack_env_setter
      )
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )
      context = OpenTelemetry.baggage.build(context: context) do |baggage|
        baggage.set_entry('key-1', 'value1')
        baggage.set_entry('key-2', 'value2')
      end
      carrier = {}
      rack_injector.inject(carrier, context)
      trace_span_identity_value = carrier['HTTP_UBER_TRACE_ID']
      trace_id, span_id, parent_span_id, flags = trace_span_identity_value.split(/:/)
      _(trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_id).must_equal('e457b5a2e4d86bd1')
      _(parent_span_id).must_equal('0')
      _(flags).must_equal('1')
      _(carrier['HTTP_UBERCTX_KEY_1']).must_equal('value1')
      _(carrier['HTTP_UBERCTX_KEY_2']).must_equal('value2')
    end

    it 'does not inject the debug flag when the sample flag is not set' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
        jaeger_debug: true
      )
      carrier = {}
      injector.inject(carrier, context)
      trace_span_identity_value = carrier[identity_key]
      _trace_id, _span_id, _parent_span_id, flags = trace_span_identity_value.split(/:/)
      _(flags).must_equal('0')
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )
      carrier = {}
      injector.inject(carrier, context)
      _(carrier.keys.empty?).must_equal(true)
    end

    it 'no-ops if span id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )
      carrier = {}
      injector.inject(carrier, context)
      _(carrier.keys.empty?).must_equal(true)
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
                     jaeger_debug: false)
    context = OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace::Span.new(
        span_context: OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
    context = OpenTelemetry::Propagator::Jaeger.context_with_debug(context) if jaeger_debug
    context
  end
end
