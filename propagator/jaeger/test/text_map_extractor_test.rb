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

  describe('#extract') do
    it 'extracts context with trace id, span id, sampling flag' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1'
      }

      context = extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(span_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id, sampling flag, parent span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:ef62c5754687a53a:1'
      }

      context = extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(span_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:0'
      }

      context = extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(span_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(span_context).must_be(:remote?)
    end

    it 'converts debug flag to sampled' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:3'
      }

      context = extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(OpenTelemetry::Propagator::Jaeger.debug?(context)).must_equal(true)
    end

    it 'handles 8-byte trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '000000000000000064fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1'
      }

      context = extractor.extract(carrier, parent_context)
      span_context = OpenTelemetry::Trace.current_span(context).context

      _(span_context.hex_trace_id).must_equal('000000000000000064fe8b2a57d3eff7')
    end

    it 'extracts baggage' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d86bd1:0:1',
        'uberctx-key1' => 'value1',
        'uberctx-key2' => 'value2'
      }

      context = extractor.extract(carrier, parent_context)
      _(OpenTelemetry.baggage.value('key1', context: context)).must_equal('value1')
      _(OpenTelemetry.baggage.value('key2', context: context)).must_equal('value2')
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
      _(OpenTelemetry.baggage.value('key-1', context: context)).must_equal('value1')
      _(OpenTelemetry.baggage.value('key-2', context: context)).must_equal('value2')
    end

    it 'handles malformed trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864feb2a:e457b5a2e4d86bd1:0:1'
      }

      context = extractor.extract(carrier, parent_context)
      _(context).must_equal(parent_context)
    end

    it 'handles malformed span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = {
        'uber-trace-id' => '80f198ee56343ba864fe8b2a57d3eff7:e457b5a2e4d1:0:1'
      }

      context = extractor.extract(carrier, parent_context)
      _(context).must_equal(parent_context)
    end
  end
end
