# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-sdk'

describe OpenTelemetry::Propagator::Jaeger::TextMapExtractor do
  let(:extractor) { OpenTelemetry::Propagator::Jaeger::TextMapExtractor.new }

  before do
    OpenTelemetry::SDK::Configurator.new.configure
  end

  def extract_context(header)
    parent_context = OpenTelemetry::Context.empty
    carrier = { 'uber-trace-id' => header }
    extractor.extract(carrier, parent_context)
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
    context = extractor.extract(carrier, parent_context)
    _(context).must_equal(parent_context)
  end

  describe('#extract') do
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

      context = extractor.extract(carrier, parent_context)
      _(OpenTelemetry.baggage.entry('key1', context: context).value).must_equal('value1')
      _(OpenTelemetry.baggage.entry('key2', context: context).value).must_equal('value2')
    end

    it 'extracts URL-encoded baggage.entries' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'uberctx-key1' => 'value%201%20%2F%20blah'
      }

      context = extractor.extract(carrier, parent_context)
      _(OpenTelemetry.baggage.entry('key1', context: context).value).must_equal('value 1 / blah')
    end

    it 'extracts baggage with different keys' do
      rack_extractor = OpenTelemetry::Propagator::Jaeger::TextMapExtractor.new(
        OpenTelemetry::Context::Propagation.rack_env_getter
      )
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'HTTP_UBER_TRACE_ID' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'HTTP_UBERCTX_KEY_1' => 'value1',
        'HTTP_UBERCTX_KEY_2' => 'value2'
      }

      context = rack_extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context
      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(OpenTelemetry.baggage.entry('key-1', context: context).value).must_equal('value1')
      _(OpenTelemetry.baggage.entry('key-2', context: context).value).must_equal('value2')
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
  end
end
