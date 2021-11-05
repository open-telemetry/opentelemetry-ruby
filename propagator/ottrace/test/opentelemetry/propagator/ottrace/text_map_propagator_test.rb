# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::OTTrace::TextMapPropagator do
  class FakeGetter
    def get(carrier, key)
      case key
      when 'ot-tracer-traceid', 'ot-tracer-spanid'
        carrier[key].reverse
      when 'ot-tracer-sampled'
        carrier[key] != 'true'
      end
    end

    def keys(carrier)
      []
    end
  end

  class FakeSetter
    def set(carrier, key, value)
      carrier[key] = "#{key} = #{value}"
    end
  end

  let(:span_id) do
    'e457b5a2e4d86bd1'
  end

  let(:truncated_trace_id) do
    '64fe8b2a57d3eff7'
  end

  let(:trace_id) do
    '80f198ee56343ba864fe8b2a57d3eff7'
  end

  let(:trace_flags) do
    OpenTelemetry::Trace::TraceFlags::DEFAULT
  end

  let(:context) do
    OpenTelemetry::Trace.context_with_span(
      OpenTelemetry::Trace.non_recording_span(
        OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end

  let(:baggage) do
    OpenTelemetry::Baggage
  end

  let(:propagator) do
    OpenTelemetry::Propagator::OTTrace::TextMapPropagator.new
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
      'ot-tracer-traceid' => trace_id_header,
      'ot-tracer-spanid' => span_id_header,
      'ot-tracer-sampled' => sampled_header
    }
  end

  describe '#extract' do
    describe 'given an empty context' do
      let(:carrier) do
        {}
      end

      it 'skips context extraction' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('0' * 32)
        _(extracted_context.hex_span_id).must_equal('0' * 16)
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).wont_be(:remote?)
      end
    end

    describe 'given a minimal context' do
      it 'extracts parent context' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a minimal context with uppercase fields' do
      let(:carrier) do
        {
          'ot-tracer-traceid' => trace_id_header.upcase,
          'ot-tracer-spanid' => span_id_header.upcase,
          'ot-tracer-sampled' => sampled_header
        }
      end

      it 'extracts parent context' do
        context = propagator.extract(carrier, context: parent_context)
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
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with sampling bit set to enabled' do
      let(:sampled_header) do
        '1'
      end

      it 'extracts sampled trace flag' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
        _(extracted_context.hex_span_id).must_equal('e457b5a2e4d86bd1')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::SAMPLED)
        _(extracted_context).must_be(:remote?)
      end
    end

    describe 'given a context with a sampling bit set to disabled' do
      let(:sampled_header) do
        '0'
      end

      it 'extracts a default trace flag' do
        context = propagator.extract(carrier, context: parent_context)
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
        context = propagator.extract(carrier, context: parent_context)
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
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'given context with a malformed span id' do
      let(:span_id_header) do
        'abc123'
      end

      it 'skips content extraction' do
        context = propagator.extract(carrier, context: parent_context)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context).must_be_same_as(OpenTelemetry::Trace::SpanContext::INVALID)
      end
    end

    describe 'baggage handling' do
      describe 'given valid baggage items' do
        it 'extracts baggage items' do
          carrier_with_baggage = carrier.merge(
            'ot-baggage-foo' => 'bar',
            'ot-baggage-bar' => 'baz'
          )

          context = propagator.extract(carrier_with_baggage, context: parent_context)
          _(OpenTelemetry::Baggage.value('foo', context: context)).must_equal('bar')
          _(OpenTelemetry::Baggage.value('bar', context: context)).must_equal('baz')
        end
      end

      describe 'given invalid baggage keys' do
        it 'omits entries' do
          carrier_with_baggage = carrier.merge(
            'ot-baggage-f00' => 'bar',
            'ot-baggage-bar' => 'baz'
          )

          context = propagator.extract(carrier_with_baggage, context: parent_context)
          _(OpenTelemetry::Baggage.value('fθθ', context: context)).must_be_nil
          _(OpenTelemetry::Baggage.value('bar', context: context)).must_equal('baz')
        end
      end

      describe 'given invalid baggage values' do
        it 'omits entries' do
          carrier_with_baggage = carrier.merge(
            'ot-baggage-foo' => 'bαr',
            'ot-baggage-bar' => 'baz'
          )

          context = propagator.extract(carrier_with_baggage, context: parent_context)
          _(OpenTelemetry::Baggage.value('foo', context: context)).must_be_nil
          _(OpenTelemetry::Baggage.value('bar', context: context)).must_equal('baz')
        end
      end
    end

    describe 'given an alternative getter parameter' do
      it 'will use the alternative getter instead of the constructor provided one' do
        context = propagator.extract(carrier, context: parent_context, getter: FakeGetter.new)
        extracted_context = OpenTelemetry::Trace.current_span(context).context

        _(extracted_context.hex_trace_id).must_equal('7ffe3d75a2b8ef468ab34365ee891f08')
        _(extracted_context.hex_span_id).must_equal('1db68d4e2a5b754e')
        _(extracted_context.trace_flags).must_equal(OpenTelemetry::Trace::TraceFlags::DEFAULT)
        _(extracted_context).must_be(:remote?)
      end
    end
  end

  describe '#inject' do
    describe 'when provided invalid trace ids' do
      let(:trace_id) do
        '0' * 32
      end

      it 'skips injecting context' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'when provided invalid span ids' do
      let(:span_id) do
        '0' * 16
      end

      it 'skips injecting context' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier).must_be_empty
      end
    end

    describe 'given a minimal context' do
      it 'injects OpenTracing headers' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier.fetch('ot-tracer-traceid')).must_equal(truncated_trace_id)
        _(carrier.fetch('ot-tracer-spanid')).must_equal(span_id)
        _(carrier.fetch('ot-tracer-sampled')).must_equal('false')
      end
    end

    describe 'given a sampled trace flag' do
      let(:trace_flags) do
        OpenTelemetry::Trace::TraceFlags::SAMPLED
      end

      it 'injects OpenTracing headers' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier.fetch('ot-tracer-traceid')).must_equal(truncated_trace_id)
        _(carrier.fetch('ot-tracer-spanid')).must_equal(span_id)
        _(carrier.fetch('ot-tracer-sampled')).must_equal('true')
      end
    end

    describe 'given a trace id that exceeds the 64 BIT/16 HEXDIG limit' do
      let(:trace_id) do
        '80f198ee56343ba864fe8b2a57d3eff7'
      end

      it 'injects truncates the trace id header' do
        carrier = {}
        propagator.inject(carrier, context: context)

        _(carrier.fetch('ot-tracer-traceid')).must_equal('64fe8b2a57d3eff7')
        _(carrier.fetch('ot-tracer-spanid')).must_equal(span_id)
        _(carrier.fetch('ot-tracer-sampled')).must_equal('false')
      end
    end

    describe 'baggage handling' do
      describe 'given valid baggage items' do
        it 'injects baggage items' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_value('foo', 'bar')
            builder.set_value('bar', 'baz')
          end

          carrier = {}
          propagator.inject(carrier, context: context_with_baggage)

          _(carrier.fetch('ot-baggage-foo')).must_equal('bar')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end

      describe 'given invalid baggage keys' do
        it 'omits entries' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_value('fθθ', 'bar')
            builder.set_value('bar', 'baz')
          end

          carrier = {}
          propagator.inject(carrier, context: context_with_baggage)

          _(carrier.keys).wont_include('ot-baggage-f00')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end

      describe 'given invalid baggage values' do
        it 'omits entries' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_value('foo', 'bαr')
            builder.set_value('bar', 'baz')
          end

          carrier = {}
          propagator.inject(carrier, context: context_with_baggage)

          _(carrier.keys).wont_include('ot-baggage-foo')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end
    end

    describe 'given an alternative setter parameter' do
      it 'will use the alternative setter instead of the constructor provided one' do
        carrier = {}

        alternate_setter = FakeSetter.new
        propagator.inject(carrier, context: context, setter: alternate_setter)

        _(carrier.fetch('ot-tracer-traceid')).must_equal('ot-tracer-traceid = 64fe8b2a57d3eff7')
        _(carrier.fetch('ot-tracer-spanid')).must_equal('ot-tracer-spanid = e457b5a2e4d86bd1')
        _(carrier.fetch('ot-tracer-sampled')).must_equal('ot-tracer-sampled = false')
      end
    end
  end
end
