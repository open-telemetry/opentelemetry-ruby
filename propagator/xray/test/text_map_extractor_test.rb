# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay::TextMapExtractor do
  let(:extractor) { OpenTelemetry::Propagator::XRay::TextMapExtractor.new }

  describe('#extract') do
    it 'extracts context with trace id, span id, sampling flag' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=1' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(extracted_context).must_be(:remote?)
    end

    it 'converts debug flag to sampled' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=d' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
    end

    it 'handles malformed trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=180f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=1' }

      context = extractor.extract(carrier, parent_context)

      _(context).must_equal(parent_context)
    end

    it 'handles malformed span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'X-Amzn-Trace-Id' => 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=457b5a2e4d86bd1;Sampled=1' }

      context = extractor.extract(carrier, parent_context)

      _(context).must_equal(parent_context)
    end
  end
end
