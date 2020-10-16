# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Single::TextMapExtractor do
  let(:extractor) { OpenTelemetry::Propagator::B3::Single::TextMapExtractor.new }

  describe('#extract') do
    it 'extracts context with trace id, span id, sampling flag, parent span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-1-05e3ac9a4f6e3b90' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id, sampling flag' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-1' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
      _(extracted_context).must_be(:remote?)
    end

    it 'extracts context with trace id, span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
      _(extracted_context).must_be(:remote?)
    end

    it 'pads 8 byte id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '64fe8b2a57d3eff7-e457b5a2e4d86bd1' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.hex_trace_id).must_equal('000000000000000064fe8b2a57d3eff7')
    end

    it 'converts debug flag to sampled' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-d' }

      context = extractor.extract(carrier, parent_context)
      extracted_context = OpenTelemetry::Trace.current_span(context).context

      _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
    end

    it 'handles malformed trace id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864feb2a-e457b5a2e4d86bd1' }

      context = extractor.extract(carrier, parent_context)

      _(context).must_equal(parent_context)
    end

    it 'handles malformed span id' do
      parent_context = OpenTelemetry::Context.empty
      carrier = { 'b3' => '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d1' }

      context = extractor.extract(carrier, parent_context)

      _(context).must_equal(parent_context)
    end
  end
end
