# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-sdk'

describe OpenTelemetry::Propagator::Jaeger::TextMapPropagator do
  let(:propagator) { OpenTelemetry::Propagator::Jaeger::TextMapPropagator.new }

  before do
    OpenTelemetry::SDK::Configurator.new.configure
  end

  describe('#extract') do
    def extract_context(header)
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'uber-trace-id' => header }
      propagator.extract(carrier, context: parent_context)
    end

    def extract_span_context(header)
      context = extract_context(header)
      OpenTelemetry::Trace.current_span(context).context
    end

    def extracted_context_must_equal_parent_context(header)
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => header
      }
      context = propagator.extract(carrier, context: parent_context)
      _(context).must_equal(parent_context)
    end

    it 'extracts context with trace id, span id, sampling flag' do
      span_context = extract_span_context(
        '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1'
      )
      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(span_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id, sampling flag, parent span id' do
      span_context = extract_span_context(
        '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:ef62c5754687a53a:1'
      )
      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(span_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      span_context = extract_span_context(
        '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:0'
      )
      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(span_context).must_be(:remote?)
    end

    it 'extracts context with a shorter trace id and span id' do
      span_context = extract_span_context(
        '8ee56343ba864fe8b2a57d3eff7:5a2e4d86bd1:0:1'
      )
      _(span_context.hex_trace_id).must_equal('000008ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('000005a2e4d86bd1')
    end

    it 'extracts context with 64-bit trace ids' do
      span_context = extract_span_context(
        '80f198ee56343ba8:e457b5a2e4d86bd1:0:1'
      )
      _(span_context.hex_trace_id).must_equal('000000000000000080f198ee56343ba8')
    end

    it 'extracts context with a shorter trace id that can be included in a 64-bit hex string' do
      span_context = extract_span_context(
        '98ee56343ba8:e457b5a2e4d86bd1:0:1'
      )
      _(span_context.hex_trace_id).must_equal('0000000000000000000098ee56343ba8')
    end

    it 'converts debug flag to sampled' do
      context = extract_context(
        '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:3'
      )
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(OpenTelemetry::Propagator::Jaeger.debug?(context)).must_equal(true)
    end

    it 'extracts baggage' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'uberctx-key1' => 'value1',
        'uberctx-key2' => 'value2'
      }

      context = propagator.extract(carrier, context: parent_context)
      _(OpenTelemetry::Baggage.value('key1', context: context)).must_equal('value1')
      _(OpenTelemetry::Baggage.value('key2', context: context)).must_equal('value2')
    end

    it 'extracts URL-encoded baggage entries' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'uberctx-key1' => 'value%201%20%2F%20blah'
      }

      context = propagator.extract(carrier, context: parent_context)
      _(OpenTelemetry::Baggage.value('key1', context: context)).must_equal('value 1 / blah')
    end

    it 'extracts baggage with different keys' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'HTTP_UBER_TRACE_ID' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'HTTP_UBERCTX_KEY_1' => 'value1',
        'HTTP_UBERCTX_KEY_2' => 'value2'
      }

      context = propagator.extract(
        carrier,
        context: parent_context,
        getter: OpenTelemetry::Common::Propagation.rack_env_getter
      )
      span_context = OpenTelemetry::Trace.current_span(context).context
      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(OpenTelemetry::Baggage.value('key-1', context: context)).must_equal('value1')
      _(OpenTelemetry::Baggage.value('key-2', context: context)).must_equal('value2')
    end

    it 'handles trace ids and span ids that are too long' do
      extracted_context_must_equal_parent_context(
        '80f198ee56343ba864fe8b2a57d3eff7eff7:e457b5a2e4d86bd1:0:1'
      )
      extracted_context_must_equal_parent_context(
        '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd16bd1:0:1'
      )
    end

    it 'handles invalid 0 trace id and 0 span id' do
      extracted_context_must_equal_parent_context('0:e457b5a2e4d86bd1:0:1')
      extracted_context_must_equal_parent_context(
        '80f198ee56343ba864fe8b2a57d3eff7:0:0:1'
      )
      extracted_context_must_equal_parent_context('00:00:0:1')
    end

    it 'handles missing trace context' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {}
      context = propagator.extract(carrier, context: parent_context)
      _(context).must_equal(parent_context)
    end
  end

  describe '#inject' do
    let(:identity_key) { 'uber-trace-id' }

    def create_context(trace_id:,
                       span_id:,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
                       jaeger_debug: false)
      context = OpenTelemetry::Trace.context_with_span(
        OpenTelemetry::Trace.non_recording_span(
          OpenTelemetry::Trace::SpanContext.new(
            trace_id: Array(trace_id).pack('H*'),
            span_id: Array(span_id).pack('H*'),
            trace_flags: trace_flags
          )
        )
      )
      context = OpenTelemetry::Propagator::Jaeger.context_with_debug(context) if jaeger_debug
      context
    end

    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )
      carrier = {}
      propagator.inject(carrier, context: context)
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
      propagator.inject(carrier, context: context)
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
      propagator.inject(carrier, context: context)
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
      context = OpenTelemetry::Baggage.build(context: context) do |baggage|
        baggage.set_value('key1', 'value1')
        baggage.set_value('key2', 'value2')
      end
      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier['uberctx-key1']).must_equal('value1')
      _(carrier['uberctx-key2']).must_equal('value2')
    end

    it 'URL-encodes baggage values before injecting' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1'
      )
      context = OpenTelemetry::Baggage.build(context: context) do |baggage|
        baggage.set_value('key1', 'value 1 / blah')
      end
      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier['uberctx-key1']).must_equal('value+1+%2F+blah')
    end

    it 'injects to rack keys' do
      rack_env_setter = Object.new
      def rack_env_setter.set(carrier, key, value)
        # Use + for mutable string interpolation in pre-Ruby 3.0.
        rack_key = +"HTTP_#{key}"
        rack_key.tr!('-', '_')
        rack_key.upcase!
        carrier[rack_key] = value
      end
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )
      context = OpenTelemetry::Baggage.build(context: context) do |baggage|
        baggage.set_value('key-1', 'value1')
        baggage.set_value('key-2', 'value2')
      end
      carrier = {}
      propagator.inject(carrier, context: context, setter: rack_env_setter)
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
      propagator.inject(carrier, context: context)
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
      propagator.inject(carrier, context: context)
      _(carrier.keys.empty?).must_equal(true)
    end

    it 'no-ops if span id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )
      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier.keys.empty?).must_equal(true)
    end
  end
end
