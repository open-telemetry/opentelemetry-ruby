# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

module OpenTelemetry
  module Propagator
    module OTTrace
      class TextMapInjector
        # Returns a new TextMapInjector that injects context using the specified setter
        #
        # @param [optional Setter] default_setter The default setter used to
        #   write context into a carrier during inject. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapSetter} instance.
        # @return [TextMapInjector]
        def initialize(default_setter = Context::Propagation.text_map_setter)
          @default_setter = default_setter
        end

        # @param [Context] context The active Context.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        # @return [Object] the carrier with context injected
        def inject(carrier, context, setter = default_setter)
          span_context = Trace.current_span(context).context
          return carrier unless span_context.valid?

          setter.set(carrier, TRACE_ID_HEADER, span_context.hex_trace_id)
          setter.set(carrier, SPAN_ID_HEADER, span_context.hex_span_id)
          setter.set(carrier, SAMPLED_HEADER, false)
          carrier
        end

        private

        attr_reader :default_setter
      end
    end
  end
end

describe OpenTelemetry::Propagator::OTTrace::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  OTTrace = OpenTelemetry::Propagator::OTTrace

  let(:span_id) do
    'e457b5a2e4d86bd1'
  end

  let(:trace_id) do
    '64fe8b2a57d3eff7'
  end

  let(:context) do
    OpenTelemetry::Trace.context_with_span(
      Span.new(
        span_context: SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*')
        )
      )
    )
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
        _(updated_carrier.fetch(OTTrace::SAMPLED_HEADER)).must_equal(false)
      end
    end
  end
end
