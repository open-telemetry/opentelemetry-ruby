# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext::ResponseTextMapPropagator do
  let(:traceresponse_key) { 'traceresponse' }
  let(:propagator) do
    OpenTelemetry::Trace::Propagation::TraceContext::ResponseTextMapPropagator.new
  end

  let(:carrier) do
    {
      traceresponse_key => valid_traceresponse_header
    }
  end
  let(:context) { OpenTelemetry::Context.empty }
  let(:context_valid) do
    span_context = OpenTelemetry::Trace::SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b)
    span = OpenTelemetry::Trace.non_recording_span(span_context)
    OpenTelemetry::Trace.context_with_span(span)
  end

  describe '#inject' do
    it 'writes traceresponse into the carrier' do
      carrier = {}
      propagator.inject(carrier, context: context_valid)
      _(carrier[traceresponse_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
    end

    it "doesn't write if the context is not valid" do
      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier).wont_include(traceresponse_key)
    end
  end
end
