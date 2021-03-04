# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

module OpenTelemetry
  module Propagator
    module OTTrace
      class TextMapInjector
        TRACE_ID_64_BIT_WIDTH = 64 / 4

        # Returns a new TextMapInjector that injects context using the specified setter
        #
        # @param [optional Setter] default_setter The default setter used to
        #   write context into a carrier during inject. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapSetter} instance.
        # @param [optional BaggageManager] baggage_manager Provides access to
        #   baggage values to write into the carrier during inject.
        #   write context into a carrier during inject
        # @return [TextMapInjector]
        def initialize(
          baggage_manager:,
          default_setter: Context::Propagation.text_map_setter
        )
          @default_setter = default_setter
          @baggage_manager = baggage_manager
        end

        # @param [Context] context The active Context.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        # @return [Object] the carrier with context injected
        def inject(carrier, context, setter = default_setter)
          span_context = Trace.current_span(context).context
          return carrier unless span_context.valid?

          setter.set(carrier, TRACE_ID_HEADER, span_context.hex_trace_id[-TRACE_ID_64_BIT_WIDTH, TRACE_ID_64_BIT_WIDTH])
          setter.set(carrier, SPAN_ID_HEADER, span_context.hex_span_id)
          setter.set(carrier, SAMPLED_HEADER, span_context.trace_flags.sampled?.to_s)

          puts baggage_manager.inspect
          baggage_manager.values(context: context).each do |key, value|
            setter.set(carrier, "#{BAGGAGE_HEADER_PREFIX}#{key}", value)
          end
          carrier
        end

        private

        attr_reader :default_setter
        attr_reader :baggage_manager
      end
    end
  end
end

describe OpenTelemetry::Propagator::OTTrace::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags
  OTTrace = OpenTelemetry::Propagator::OTTrace
  ContextKeys = OpenTelemetry::Baggage::Propagation::ContextKeys

  let(:span_id) do
    'e457b5a2e4d86bd1'
  end

  let(:trace_id) do
    '64fe8b2a57d3eff7'
  end

  let(:trace_flags) do
    TraceFlags::DEFAULT
  end

  let(:context) do
    OpenTelemetry::Trace.context_with_span(
      Span.new(
        span_context: SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end

  let(:baggage_manager) do
    OpenTelemetry.baggage
  end

  let(:injector) do
    OpenTelemetry::Propagator::OTTrace::TextMapInjector.new(baggage_manager: baggage_manager)
  end

  before do
    OpenTelemetry::SDK::Configurator.new.configure
  end

  describe '#inject' do
    describe 'when provided invalid trace ids' do
      let(:trace_id) do
        '0' * 32
      end

      it 'skips injecting context' do
        carrier = {}
        updated_carrier = injector.inject(carrier, context)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier).must_be_empty
      end
    end

    describe 'when provided invalid span ids' do
      let(:span_id) do
        '0' * 16
      end

      it 'skips injecting context' do
        carrier = {}
        updated_carrier = injector.inject(carrier, context)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier).must_be_empty
      end
    end

    describe 'given a minimal context' do
      it 'injects OpenTracing headers' do
        carrier = {}
        updated_carrier = injector.inject(carrier, context)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier.fetch(OTTrace::TRACE_ID_HEADER)).must_equal(trace_id)
        _(updated_carrier.fetch(OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(updated_carrier.fetch(OTTrace::SAMPLED_HEADER)).must_equal('false')
      end
    end

    describe 'given a sampled trace flag' do
      let(:trace_flags) do
        TraceFlags::SAMPLED
      end

      it 'injects OpenTracing headers' do
        carrier = {}
        updated_carrier = injector.inject(carrier, context)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier.fetch(OTTrace::TRACE_ID_HEADER)).must_equal(trace_id)
        _(updated_carrier.fetch(OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(updated_carrier.fetch(OTTrace::SAMPLED_HEADER)).must_equal('true')
      end
    end

    describe 'given a trace id that exceeds the 64 BIT/16 HEXDIG limit' do
      let(:trace_id) do
        '80f198ee56343ba864fe8b2a57d3eff7'
      end

      it 'injects truncates the trace id header' do
        carrier = {}
        updated_carrier = injector.inject(carrier, context)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier.fetch(OTTrace::TRACE_ID_HEADER)).must_equal('64fe8b2a57d3eff7')
        _(updated_carrier.fetch(OTTrace::SPAN_ID_HEADER)).must_equal(span_id)
        _(updated_carrier.fetch(OTTrace::SAMPLED_HEADER)).must_equal('false')
      end
    end

    describe 'baggage handling' do
      it 'injects baggage items' do
        context_with_baggage = baggage_manager.build_context(context: context) do |builder|
          builder.set_value('foo', 'bar')
          builder.set_value('bar', 'baz')
        end

        carrier = {}
        updated_carrier = injector.inject(carrier, context_with_baggage)
        _(updated_carrier).must_be_same_as(carrier)
        _(updated_carrier.fetch('ot-baggage-foo')).must_equal('bar')
        _(updated_carrier.fetch('ot-baggage-baz')).must_equal('baz')
      end
    end
  end
end
