# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporters::Jaeger::Exporter::SpanEncoder do
  let(:span_encoder) { OpenTelemetry::Exporters::Jaeger::Exporter::SpanEncoder.new }

  it 'encodes a span_data' do
    encoded_span = span_encoder.encoded_span(create_span_data)
    _(encoded_span.operationName).must_equal('')
    _(encoded_span.tags).must_equal([])
  end

  it 'encodes attributes in events and the span' do
    attributes = { 'akey' => 'avalue' }
    events = [
      OpenTelemetry::Trace::Event.new(
        name: 'event', attributes: { 'ekey' => 'evalue' }
      )
    ]
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = span_encoder.encoded_span(span_data)
    field0 = encoded_span.logs.first.fields.first
    _(field0.key).must_equal('ekey')
    _(field0.vType).must_equal(
      OpenTelemetry::Exporters::Jaeger::Thrift::TagType::STRING
    )
    _(field0.vStr).must_equal('evalue')
    tag0 = encoded_span.tags.first
    _(tag0.key).must_equal('akey')
    _(tag0.vStr).must_equal('avalue')
    _(tag0.vType).must_equal(
      OpenTelemetry::Exporters::Jaeger::Thrift::TagType::STRING
    )
  end

  it 'encodes array attribute values in events and the span as JSON strings' do
    attributes = { 'akey' => ['avalue'] }
    events = [
      OpenTelemetry::Trace::Event.new(
        name: 'event', attributes: { 'ekey' => ['evalue'] }
      )
    ]
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = span_encoder.encoded_span(span_data)
    field0 = encoded_span.logs.first.fields.first
    _(field0.key).must_equal('ekey')
    _(field0.vType).must_equal(
      OpenTelemetry::Exporters::Jaeger::Thrift::TagType::STRING
    )
    _(field0.vStr).must_equal('["evalue"]')
    tag0 = encoded_span.tags.first
    _(tag0.key).must_equal('akey')
    _(tag0.vStr).must_equal('["avalue"]')
    _(tag0.vType).must_equal(
      OpenTelemetry::Exporters::Jaeger::Thrift::TagType::STRING
    )
  end

  def create_span_data(attributes: nil, events: nil, links: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    OpenTelemetry::SDK::Trace::SpanData.new(
      '',
      nil,
      nil,
      OpenTelemetry::Trace::INVALID_SPAN_ID,
      0,
      0,
      0,
      0,
      Time.now,
      Time.now,
      attributes,
      links,
      events,
      nil,
      nil,
      OpenTelemetry::Trace.generate_span_id,
      trace_id,
      trace_flags,
      tracestate
    )
  end
end
