# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Multi::TextMapPropagator do
  let(:propagator) { OpenTelemetry::Propagator::B3::Multi::TextMapPropagator.new }
  let(:trace_id_key) { 'X-B3-TraceId' }
  let(:span_id_key) { 'X-B3-SpanId' }
  let(:parent_span_id_key) { 'X-B3-ParentSpanId' }
  let(:sampled_key) { 'X-B3-Sampled' }
  let(:flags_key) { 'X-B3-Flags' }
  let(:all_keys) { [trace_id_key, span_id_key, parent_span_id_key, sampled_key, flags_key] }

  describe('#extract') do
    it 'extracts context with trace id, span id, sampling flag, parent span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d86bd1',
        sampled_key => '1',
        parent_span_id_key => '05e3ac9a4f6e3b90'
      }
      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id, sampling flag' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d86bd1',
        sampled_key => '1'
      }
      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d86bd1'
      }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(extracted_context).must_be(:remote?)
    end

    it 'pads 8 byte id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '64fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d86bd1'
      }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('000000000000000064fe8b2a57d3eff7')
    end

    it 'converts debug flag to sampled' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d86bd1',
        sampled_key => '1'
      }

      context = propagator.extract(carrier, context: parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
    end

    it 'handles malformed trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864feb2a',
        span_id_key => 'e457b5a2e4d86bd1'
      }

      context = propagator.extract(carrier, context: parent_context)

      _(context).must_equal(parent_context)
    end

    it 'handles malformed span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        trace_id_key => '80f198ee56343ba864fe8b2a57d3eff7',
        span_id_key => 'e457b5a2e4d1'
      }

      context = propagator.extract(carrier, context: parent_context)

      _(context).must_equal(parent_context)
    end
  end

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[sampled_key]).must_equal('1')
      _(carrier.key?(flags_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[sampled_key]).must_equal('0')
      _(carrier.key?(flags_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'injects debug flag when present' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        b3_debug: true
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[flags_key]).must_equal('1')
      _(carrier.key?(sampled_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      all_keys.each { |k| _(carrier.key?(k)).must_equal(false) }
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )

      carrier = {}
      propagator.inject(carrier, context: context)

      all_keys.each { |k| _(carrier.key?(k)).must_equal(false) }
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
                     b3_debug: false)
    context = OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace.non_recording_span(
        OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
    context = OpenTelemetry::Propagator::B3.context_with_debug(context) if b3_debug
    context
  end
end
