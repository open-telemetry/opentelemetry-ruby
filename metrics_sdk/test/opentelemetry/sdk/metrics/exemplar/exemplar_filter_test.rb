# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::ExemplarFilter do

  let(:context) { ::OpenTelemetry::Trace.context_with_span(
                    ::OpenTelemetry::Trace.non_recording_span(
                      ::OpenTelemetry::Trace::SpanContext.new(
                        trace_id: Array("w\xCBl\xCCR-1\x06\x11M\xD6\xEC\xBBp\x03j").pack('H*'),
                        span_id: Array("1\xE1u\x12\x8E\xFC@\x18").pack('H*'),
                        trace_flags: ::OpenTelemetry::Trace::TraceFlags::DEFAULT)))
                }
  let(:timestamp) { 123_456_789 }
  let(:attributes) { {'test': 'test'} }

  it 'always true for always on exemplar filter' do
    result = OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter.should_sample?(1, timestamp, attributes, context)
    _(result).must_equal true
  end

  it 'always false for always off exemplar filter' do
    result = OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOffExemplarFilter.should_sample?(1, timestamp, attributes, context)
    _(result).must_equal false
  end

  it 'filter off when trace context flag is 0' do
    result = OpenTelemetry::SDK::Metrics::Exemplar::TraceBasedExemplarFilter.should_sample?(1, timestamp, attributes, context)
    _(result).must_equal false
  end

  it 'filter on when trace context flag is 1' do
    context.instance_variable_get(:@entries).values[0].instance_variable_get(:@context).instance_variable_set(:@trace_flags, ::OpenTelemetry::Trace::TraceFlags::SAMPLED)
    result = OpenTelemetry::SDK::Metrics::Exemplar::TraceBasedExemplarFilter.should_sample?(1, timestamp, attributes, context)
    _(result).must_equal true
  end
end
