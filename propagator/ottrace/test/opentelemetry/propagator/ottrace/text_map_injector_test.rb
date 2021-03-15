# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::OTTrace::TextMapInjector do
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
      OpenTelemetry::Trace::Span.new(
        span_context: OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end

  let(:baggage) do
    OpenTelemetry.baggage
  end

  let(:injector) do
    OpenTelemetry::Propagator::OTTrace::TextMapInjector.new
  end

  describe '#inject' do
    describe 'when provided invalid trace ids' do
      let(:trace_id) do
        '0' * 32
      end

      it 'skips injecting context' do
        carrier = {}
        injector.inject(carrier, context)

        _(carrier).must_be_empty
      end
    end

    describe 'when provided invalid span ids' do
      let(:span_id) do
        '0' * 16
      end

      it 'skips injecting context' do
        carrier = {}
        injector.inject(carrier, context)

        _(carrier).must_be_empty
      end
    end

    describe 'given a minimal context' do
      it 'injects OpenTracing headers' do
        carrier = {}
        injector.inject(carrier, context)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal(truncated_trace_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('false')
      end
    end

    describe 'given a sampled trace flag' do
      let(:trace_flags) do
        OpenTelemetry::Trace::TraceFlags::SAMPLED
      end

      it 'injects OpenTracing headers' do
        carrier = {}
        injector.inject(carrier, context)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal(truncated_trace_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('true')
      end
    end

    describe 'given a trace id that exceeds the 64 BIT/16 HEXDIG limit' do
      let(:trace_id) do
        '80f198ee56343ba864fe8b2a57d3eff7'
      end

      it 'injects truncates the trace id header' do
        carrier = {}
        injector.inject(carrier, context)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal('64fe8b2a57d3eff7')
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('false')
      end
    end

    describe 'baggage handling' do
      before do
        OpenTelemetry.baggage = OpenTelemetry::Baggage::Manager.new
      end

      after do
        OpenTelemetry.baggage = nil
      end

      describe 'given valid baggage items' do
        it 'injects baggage items' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_entry('foo', 'bar')
            builder.set_entry('bar', 'baz')
          end

          carrier = {}
          injector.inject(carrier, context_with_baggage)

          _(carrier.fetch('ot-baggage-foo')).must_equal('bar')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end

      describe 'given invalid baggage keys' do
        it 'omits entries' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_entry('fθθ', 'bar')
            builder.set_entry('bar', 'baz')
          end

          carrier = {}
          injector.inject(carrier, context_with_baggage)

          _(carrier.keys).wont_include('ot-baggage-f00')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end

      describe 'given invalid baggage.entries' do
        it 'omits entries' do
          context_with_baggage = baggage.build(context: context) do |builder|
            builder.set_entry('foo', 'bαr')
            builder.set_entry('bar', 'baz')
          end

          carrier = {}
          injector.inject(carrier, context_with_baggage)

          _(carrier.keys).wont_include('ot-baggage-foo')
          _(carrier.fetch('ot-baggage-bar')).must_equal('baz')
        end
      end
    end

    describe 'given an alternative setter parameter' do
      it 'will use the alternative setter instead of the constructor provided one' do
        carrier = {}

        alternate_setter = FakeSetter.new
        injector.inject(carrier, context, alternate_setter)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal('ot-tracer-traceid = 64fe8b2a57d3eff7')
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal('ot-tracer-spanid = e457b5a2e4d86bd1')
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('ot-tracer-sampled = false')
      end
    end

    describe 'given a missing setter parameter' do
      it 'uses the default setter' do
        carrier = {}

        injector.inject(carrier, context, nil)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal(truncated_trace_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('false')
      end
    end

    describe 'given an alternative default setter' do
      let(:injector) do
        OpenTelemetry::Propagator::OTTrace::TextMapInjector.new(default_setter: FakeSetter.new)
      end

      it 'will use the alternative setter' do
        carrier = {}

        injector.inject(carrier, context)

        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::TRACE_ID_HEADER)).must_equal('ot-tracer-traceid = 64fe8b2a57d3eff7')
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SPAN_ID_HEADER)).must_equal('ot-tracer-spanid = e457b5a2e4d86bd1')
        _(carrier.fetch(OpenTelemetry::Propagator::OTTrace::SAMPLED_HEADER)).must_equal('ot-tracer-sampled = false')
      end
    end
  end
end
