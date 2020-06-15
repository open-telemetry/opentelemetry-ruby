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

  let(:injector) do
    OpenTelemetry::Exporters::Datadog::Propagator.new
  end
  # let(:valid_traceparent_header) do
  #   '00-000000000000000000000000000000AA-00000000000000ea-01'
  # end
  # let(:invalid_traceparent_header) do
  #   'FF-000000000000000000000000000000AA-00000000000000ea-01'
  # end

  let(:otel_span_id) do
    ('1' * 16)
  end

  let(:otel_trace_id) do
    ('f' * 32)
  end

  let(:dd_span_id) do
    otel_span_id.to_i(16)
  end

  let(:dd_trace_id) do
    otel_trace_id[16, 16].to_i(16)
  end

  let(:dd_sampled) do
    '1'
  end

  let(:dd_not_sampled) do
    '0'
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
      carrier = injector.inject({}, context) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-sampling-priority']).must_equal(dd_not_sampled)
    end

    it 'injects the datadog appropriate sampling priority into the carrier from the context, if provided' do
      carrier = injector.inject({}, context_with_trace_flags) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-sampling-priority']).must_equal(dd_sampled)
    end

    it 'injects the datadog appropriate sampling priority into the carrier from the context, if provided' do
      carrier = injector.inject({}, context_with_tracestate) { |c, k, v| c[k] = v }
      _(carrier['x-datadog-trace-id']).must_equal(dd_trace_id)
      _(carrier['x-datadog-parent-id']).must_equal(dd_span_id)
      _(carrier['x-datadog-origin']).must_equal('example_origin')
    end
  end

  describe '#extract' do
    it 'returns original context on error' do
    end

    it 'returns a remote SpanContext with fields from the datadog headers' do
    end

    it 'accounts for rack specific headers' do
    end
  end
end
