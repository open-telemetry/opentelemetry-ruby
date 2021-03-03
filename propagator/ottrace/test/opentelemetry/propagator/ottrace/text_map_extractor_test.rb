# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

module OpenTelemetry
  module Propagator
    module OTTrace
      class TextMapExtractor
        PADDING = '0' * 16

        # Returns a new TextMapExtractor that extracts OTTrace context using the
        # specified getter
        #
        # @param [optional Getter] default_getter The default getter used to read
        #   headers from a carrier during extract. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapGetter} instance.
        # @return [TextMapExtractor]
        def initialize(default_getter = Context::Propagation.text_map_getter)
          @default_getter = default_getter
        end

        # Extract OTTrace context from the supplied carrier and set the active span
        # in the given context. The original context will be returned if OTTrace
        # cannot be extracted from the carrier.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [Context] context The context to be updated with extracted context
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        # @return [Context] Updated context with active span derived from the header, or the original
        #   context if parsing fails.
        def extract(carrier, context, getter = default_getter)
          trace_id = getter.get(carrier, TRACE_ID_HEADER)
          span_id = getter.get(carrier, SPAN_ID_HEADER)
          sampled = getter.get(carrier, SAMPLED_HEADER)

          return context unless trace_id && span_id

          trace_id = trace_id.length == 16 ? "#{PADDING}#{trace_id}" : trace_id

          span_context = Trace::SpanContext.new(
            trace_id: Array(trace_id).pack('H*'),
            span_id: Array(span_id).pack('H*'),
            trace_flags: sampled == 'true' ? TraceFlags::SAMPLED : TraceFlags::DEFAULT,
            remote: true
          )

          span = Trace::Span.new(span_context: span_context)
          Trace.context_with_span(span, parent_context: context)
        end

        private

        attr_reader :default_getter
      end
    end
  end
end

describe OpenTelemetry::Propagator::OTTrace::TextMapExtractor do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags
  OTTrace = OpenTelemetry::Propagator::OTTrace

  let(:extractor) do
    OpenTelemetry::Propagator::OTTrace::TextMapExtractor.new
  end

  describe '#extract' do
    describe 'given an empty context' do
      it 'skips context extraction' do
        parent_context = OpenTelemetry::Context.empty
        carrier = {}

        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('0' * 32)
        _(extracted_context.hex_span_id).must_equal('0' * 16)
        _(extracted_context.trace_flags).must_equal(TraceFlags::DEFAULT)
        _(extracted_context).wont_be(:remote?)
      end
    end

    describe 'given a minimal context' do
      it 'extracts parent context' do
        parent_context = OpenTelemetry::Context.empty
        carrier = {
          OTTrace::TRACE_ID_HEADER => '80f198ee56343ba864fe8b2a57d3eff7',
          OTTrace::SPAN_ID_HEADER => 'e457b5a2e4d86bd1',
          OTTrace::SAMPLED_HEADER => 'true'
        }

        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with sampling disabled' do
      it 'extracts parent context' do
        parent_context = OpenTelemetry::Context.empty
        carrier = {
          OTTrace::TRACE_ID_HEADER => '80f198ee56343ba864fe8b2a57d3eff7',
          OTTrace::SPAN_ID_HEADER => 'e457b5a2e4d86bd1',
          OTTrace::SAMPLED_HEADER => 'false'
        }

        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given context with a 64 bit/16 HEXDIGIT trace id' do
      it 'pads the trace id' do
        parent_context = OpenTelemetry::Context.empty
        carrier = {
          OTTrace::TRACE_ID_HEADER => '64fe8b2a57d3eff7',
          OTTrace::SPAN_ID_HEADER => 'e457b5a2e4d86bd1',
          OTTrace::SAMPLED_HEADER => 'true'
        }

        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('000000000000000064fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given context with a malformed trace id' do
      it 'skips content extraction' do
        parent_context = OpenTelemetry::Context.empty
        carrier = {
          OTTrace::TRACE_ID_HEADER => 'abc123',
          OTTrace::SPAN_ID_HEADER => 'e457b5a2e4d86bd1',
          OTTrace::SAMPLED_HEADER => 'false'
        }

        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_nil
      end
    end
  end
end
