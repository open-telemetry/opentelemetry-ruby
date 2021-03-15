# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::OTTrace::TextMapExtractor do
  class FakeGetter
    def get(carrier, key)
      case key
      when OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER, OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER
        carrier[key].reverse
      when OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER
        carrier[key] != 'true'
      end
    end

    def keys(carrier)
      []
    end
  end

  let(:baggage) do
    OpenTelemetry.baggage
  end

  let(:extractor) do
    OpenTelemetry::Propagator::OTTrace::TextMapExtractor.new
  end

  let(:parent_context) do
    OpenTelemetry::Context.empty
  end

  let(:trace_id_header) do
    '80f198ee56343ba864fe8b2a57d3eff7'
  end

  let(:span_id_header) do
    'e457b5a2e4d86bd1'
  end

  let(:sampled_header) do
    'true'
  end

  let(:carrier) do
    {
      OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER => trace_id_header,
      OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER => span_id_header,
      OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER => sampled_header
    }
  end

  describe '#extract' do
    describe 'given an empty context' do
      let(:carrier) do
        {}
      end

      it 'skips context extraction' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('0' * 32)
        _(extracted_context.hex_span_id).must_equal('0' * 16)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).wont_be(:remote?)
      end
    end

    describe 'given a minimal context' do
      it 'extracts parent context' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with sampling disabled' do
      let(:sampled_header) do
        'false'
      end

      it 'extracts parent context' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given context with a 64 bit/16 HEXDIGIT trace id' do
      let(:trace_id_header) do
        '64fe8b2a57d3eff7'
      end

      it 'pads the trace id' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('000000000000000064fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given context with a malformed trace id' do
      let(:trace_id_header) do
        'abc123'
      end

      it 'skips content extraction' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'given context with a malformed span id' do
      let(:span_id_header) do
        'abc123'
      end

      it 'skips content extraction' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'baggage handling' do
      before do
        OpenTelemetry.baggage = OpenTelemetry::SDK::Baggage::Manager.new
      end

      after do
        OpenTelemetry.baggage = nil
      end

      describe 'given valid baggage items' do
        it 'extracts baggage items' do
          carrier_with_baggage = carrier.merge(
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}foo" => 'bar',
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}bar" => 'baz'
          )

          context = extractor.extract(carrier_with_baggage, parent_context)
          _(OpenTelemetry.baggage.value('foo', context: context).value).must_equal('bar')
          _(OpenTelemetry.baggage.value('bar', context: context).value).must_equal('baz')
        end
      end

      describe 'given invalid baggage keys' do
        it 'omits entries' do
          carrier_with_baggage = carrier.merge(
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}fθθ" => 'bar',
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}bar" => 'baz'
          )

          context = extractor.extract(carrier_with_baggage, parent_context)
          _(OpenTelemetry.baggage.value('fθθ', context: context)).must_be_nil
          _(OpenTelemetry.baggage.value('bar', context: context).value).must_equal('baz')
        end
      end

      describe 'given invalid baggage values' do
        it 'omits entries' do
          carrier_with_baggage = carrier.merge(
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}foo" => 'bαr',
            "#{OpenTelemetry::Propagator::OTTrace::BAGGAGE_HEADER_PREFIX}bar" => 'baz'
          )

          context = extractor.extract(carrier_with_baggage, parent_context)
          _(OpenTelemetry.baggage.value('foo', context: context)).must_be_nil
          _(OpenTelemetry.baggage.value('bar', context: context).value).must_equal('baz')
        end
      end
    end

    describe 'given an alternative getter parameter' do
      it 'will use the alternative getter instead of the constructor provided one' do
        context = extractor.extract(carrier, parent_context, FakeGetter.new)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('7ffe3d75a2b8ef468ab34365ee891f08')
        _(extracted_context.hex_span_id).must_equal('1db68d4e2a5b754e')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a missing getter parameter' do
      it 'will use the default getter' do
        context = extractor.extract(carrier, parent_context, nil)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given an alternative default getter' do
      let(:extractor) do
        OpenTelemetry::Propagator::OTTrace::TextMapExtractor.new(default_getter: FakeGetter.new)
      end

      it 'will use the alternative getter' do
        context = extractor.extract(carrier, parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('7ffe3d75a2b8ef468ab34365ee891f08')
        _(extracted_context.hex_span_id).must_equal('1db68d4e2a5b754e')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end
  end
end
