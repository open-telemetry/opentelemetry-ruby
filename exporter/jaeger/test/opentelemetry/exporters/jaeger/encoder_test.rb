# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Jaeger::Encoder do
  Encoder = OpenTelemetry::Exporter::Jaeger::Encoder

  it 'encodes a span_data' do
    encoded_span = Encoder.encoded_span(create_span_data)
    _(encoded_span.operationName).must_equal('')
    _(encoded_span.tags).must_equal([])
  end

  it 'encodes a resource' do
    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
    encoded_process = Encoder.encoded_process(resource)
    _(encoded_process.serviceName).must_equal('foo')
    _(encoded_process.tags.size).must_equal(1)
    _(encoded_process.tags.first.key).must_equal('bar')
    _(encoded_process.tags.first.vStr).must_equal('baz')
    _(encoded_process.tags.first.vType).must_equal(
      OpenTelemetry::Exporter::Jaeger::Thrift::TagType::STRING
    )
  end

  it 'encodes attributes in events and the span' do
    attributes = { 'akey' => 'avalue' }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        name: 'event', attributes: { 'ekey' => 'evalue' }
      )
    ]
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Encoder.encoded_span(span_data)
    field0 = encoded_span.logs.first.fields.first
    _(field0.key).must_equal('ekey')
    _(field0.vType).must_equal(
      OpenTelemetry::Exporter::Jaeger::Thrift::TagType::STRING
    )
    _(field0.vStr).must_equal('evalue')
    tag0 = encoded_span.tags.first
    _(tag0.key).must_equal('akey')
    _(tag0.vStr).must_equal('avalue')
    _(tag0.vType).must_equal(
      OpenTelemetry::Exporter::Jaeger::Thrift::TagType::STRING
    )
  end

  it 'encodes array attribute values in events and the span as JSON strings' do
    attributes = { 'akey' => ['avalue'] }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        name: 'event', attributes: { 'ekey' => ['evalue'] }
      )
    ]
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Encoder.encoded_span(span_data)
    field0 = encoded_span.logs.first.fields.first
    _(field0.key).must_equal('ekey')
    _(field0.vType).must_equal(
      OpenTelemetry::Exporter::Jaeger::Thrift::TagType::STRING
    )
    _(field0.vStr).must_equal('["evalue"]')
    tag0 = encoded_span.tags.first
    _(tag0.key).must_equal('akey')
    _(tag0.vStr).must_equal('["avalue"]')
    _(tag0.vType).must_equal(
      OpenTelemetry::Exporter::Jaeger::Thrift::TagType::STRING
    )
  end

  describe 'instrumentation library' do
    it 'encodes library and version when set' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib', '0.1.0')
      span_data = create_span_data(instrumentation_library: lib)
      encoded_span = Encoder.encoded_span(span_data)

      _(encoded_span.tags.size).must_equal(2)

      name_tag, version_tag = encoded_span.tags

      _(name_tag.key).must_equal('otel.instrumentation_library.name')
      _(name_tag.vStr).must_equal('mylib')

      _(version_tag.key).must_equal('otel.instrumentation_library.version')
      _(version_tag.vStr).must_equal('0.1.0')
    end

    it 'skips nil values' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib')
      span_data = create_span_data(instrumentation_library: lib)
      encoded_span = Encoder.encoded_span(span_data)

      _(encoded_span.tags.size).must_equal(1)

      name_tag, = encoded_span.tags

      _(name_tag.key).must_equal('otel.instrumentation_library.name')
      _(name_tag.vStr).must_equal('mylib')
    end
  end

  def create_span_data(attributes: nil, events: nil, links: nil, instrumentation_library: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
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
      instrumentation_library,
      OpenTelemetry::Trace.generate_span_id,
      trace_id,
      trace_flags,
      tracestate
    )
  end
end
