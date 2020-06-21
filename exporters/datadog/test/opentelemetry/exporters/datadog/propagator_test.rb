# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporters::Datadog::Exporter do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext

  let(:current_span_key) do
    ::OpenTelemetry::Trace::Propagation::ContextKeys.current_span_key
  end

  let(:extracted_span_context_key) do
    ::OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key
  end

  let(:propagator) do
    OpenTelemetry::Exporters::Datadog::Propagator.new
  end

  let(:otel_span_id) do
    ('1' * 16)
  end

  let(:otel_trace_id) do
    ('f' * 32)
  end

  let(:dd_span_id) do
    otel_span_id.to_i(16).to_s
  end

  let(:dd_trace_id) do
    otel_trace_id[16, 16].to_i(16).to_s
  end

  let(:dd_sampled) do
    '1'
  end

  let(:dd_not_sampled) do
    '0'
  end

  let(:valid_dd_headers) do
    {
      'x-datadog-trace-id' => dd_trace_id,
      'x-datadog-parent-id' => dd_span_id,
      'x-datadog-sampling-priority' => dd_sampled,
      'x-datadog-origin' => 'example_origin'
    }
  end

  let(:invalid_dd_headers) do
    {
      'x-datadog-traceinvalid-id' => ('i' * 17),
      'x-datadog-parentinvalid-id' => ('i' * 17),
      'x-datadog-sampling-priority' => dd_sampled,
      'x-datadog-origin' => 'example_origin'
    }
  end

  let(:rack_dd_headers) do
    {
      'HTTP_X_DATADOG_TRACE_ID' => dd_trace_id,
      'HTTP_X_DATADOG_PARENT_ID' => dd_span_id,
      'HTTP_X_DATADOG_SAMPLING_PRIORITY' => dd_sampled,
      'HTTP_X_DATADOG_ORIGIN' => 'example_origin'
    }
  end

  let(:trace_flags) do
    OpenTelemetry::Trace::TraceFlags.from_byte(1)
  end

  let(:tracestate_header) { '_dd_origin=example_origin' }
  let(:context) do
    span_context = SpanContext.new(trace_id: otel_trace_id, span_id: otel_span_id)
    span = Span.new(span_context: span_context)
    ::OpenTelemetry::Context.empty.set_value(current_span_key, span)
  end
  let(:context_with_tracestate) do
    span_context = SpanContext.new(trace_id: otel_trace_id, span_id: otel_span_id,
                                   tracestate: tracestate_header)
    span = Span.new(span_context: span_context)
    OpenTelemetry::Context.empty.set_value(current_span_key, span)
  end

  let(:context_with_trace_flags) do
    span_context = SpanContext.new(trace_id: otel_trace_id, span_id: otel_span_id, trace_flags: trace_flags)
    span = Span.new(span_context: span_context)
    OpenTelemetry::Context.empty.set_value(current_span_key, span)
  end

  let(:context_without_current_span) do
    span_context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16,
                                   tracestate: tracestate_header)
    OpenTelemetry::Context.empty.set_value(extracted_span_context_key, span_context)
  end

  describe '#inject' do
    it 'yields the carrier' do
    end

    it 'injects the datadog appropriate trace information into the carrier from the context, if provided' do
      carrier = propagator.inject({}, context) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id.to_s)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-sampling-priority']).must_equal(dd_not_sampled)
    end

    it 'injects the datadog appropriate sampling priority into the carrier from the context, if provided' do
      carrier = propagator.inject({}, context_with_trace_flags) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-sampling-priority']).must_equal(dd_sampled)
    end

    it 'injects the datadog appropriate sampling priority into the carrier from the context, if provided' do
      carrier = propagator.inject({}, context_with_tracestate) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-origin']).must_equal('example_origin')
    end
  end

  describe '#extract' do
    it 'returns original context on error' do
      context = propagator.extract(invalid_dd_headers, OpenTelemetry::Context.empty)[extracted_span_context_key]

      assert_nil(context)
    end

    it 'returns a remote SpanContext with fields from the datadog headers' do
      context = propagator.extract(valid_dd_headers, OpenTelemetry::Context.empty)[extracted_span_context_key]

      _(context.trace_id).must_equal(otel_trace_id[0, 16])
      _(context.span_id).must_equal(otel_span_id)
      _(context.trace_flags&.sampled?).must_equal(true)
      _(context.tracestate).must_equal(tracestate_header)
    end

    it 'accounts for rack specific headers' do
      context = propagator.extract(rack_dd_headers, OpenTelemetry::Context.empty)[extracted_span_context_key]

      _(context.trace_id).must_equal(otel_trace_id[0, 16])
      _(context.span_id).must_equal(otel_span_id)
      _(context.trace_flags&.sampled?).must_equal(true)
      _(context.tracestate).must_equal(tracestate_header)
    end
  end
end
