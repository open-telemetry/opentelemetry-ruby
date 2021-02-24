# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Zipkin::Transformer do
  Transformer = OpenTelemetry::Exporter::Zipkin::Transformer

  it 'encodes a span_data and resource' do
    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
    encoded_span = Transformer.to_zipkin_span(create_span_data, resource)
    _(encoded_span[:name]).must_equal('')
    _(encoded_span[:localEndpoint]['serviceName']).must_equal('foo')
    _(encoded_span[:tags]).must_equal('bar' => 'baz', 'otel.status_code' => 'UNSET')
  end

  it 'encodes span.status and span.kind' do
    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
    span_data = create_span_data(status: OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR), kind: :server)

    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    _(encoded_span[:tags].size).must_equal(3)

    kind_tag = encoded_span[:kind]
    error_tag = encoded_span[:tags]['error']

    _(kind_tag).must_equal('SERVER')
    _(error_tag).must_equal('true')
  end

  # TODO

  it 'encodes attributes in events and the span' do
    attributes = { 'akey' => 'avalue' }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        name: 'event_with_attribs', attributes: { 'ekey' => 'evalue' }
      ),
      OpenTelemetry::SDK::Trace::Event.new(
        name: 'event_no_attrib', attributes: nil
      )
    ]

    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    annotation_one = encoded_span[:annotations].first
    annotation_two = encoded_span[:annotations][1]

    _(annotation_one[:timestamp]).must_equal((events[0].timestamp.to_f * 1_000_000).to_s)
    _(annotation_one[:value]).must_equal({ 'event_with_attribs' => { 'ekey' => 'evalue' } }.to_json)

    _(annotation_two[:timestamp]).must_equal((events[1].timestamp.to_f * 1_000_000).to_s)
    _(annotation_two[:value]).must_equal('event_no_attrib')

    tags = encoded_span[:tags]
    _(tags).must_equal('akey' => 'avalue', 'bar' => 'baz', 'otel.status_code' => 'UNSET')
  end

  it 'encodes array attribute values in events and the span as JSON strings' do
    attributes = { 'akey' => ['avalue'] }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        name: 'event_with_attribs', attributes: { 'ekey' => ['evalue'] }
      )
    ]

    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    annotation_one = encoded_span[:annotations].first

    _(annotation_one[:timestamp]).must_equal((events[0].timestamp.to_f * 1_000_000).to_s)
    _(annotation_one[:value]).must_equal({ 'event_with_attribs' => { 'ekey' => '["evalue"]' } }.to_json)

    tags = encoded_span[:tags]
    _(tags).must_equal('akey' => ['avalue'], 'bar' => 'baz', 'otel.status_code' => 'UNSET')
  end

  describe 'status' do
    it 'encodes status code as strings' do
      status = OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::OK)

      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
      span_data = create_span_data(status: status)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      tags = encoded_span[:tags]
      _(tags).must_equal('otel.status_code' => 'OK', 'bar' => 'baz')
    end

    it 'encodes error status code as strings on error tag and status description field' do
      error_description = 'there is as yet insufficient data for a meaningful answer'
      status = OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR, description: error_description)
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
      span_data = create_span_data(status: status)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      tags = encoded_span[:tags]
      _(tags).must_equal('error' => error_description, 'otel.status_description' => error_description, 'otel.status_code' => 'ERROR', 'bar' => 'baz')
    end
  end

  describe 'instrumentation library' do
    it 'encodes library and version when set' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib', '0.1.0')
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
      span_data = create_span_data(instrumentation_library: lib)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      _(encoded_span[:tags].size).must_equal(4)
      _(encoded_span[:tags]['otel.library.name']).must_equal('mylib')
      _(encoded_span[:tags]['otel.library.version']).must_equal('0.1.0')
    end

    it 'skips nil values' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib')
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar' => 'baz')
      span_data = create_span_data(instrumentation_library: lib)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      _(encoded_span[:tags].size).must_equal(3)
      _(encoded_span[:tags]['otel.library.name']).must_equal('mylib')
    end
  end

  def create_span_data(status: nil, kind: nil, attributes: nil, events: nil, links: nil, instrumentation_library: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    OpenTelemetry::SDK::Trace::SpanData.new(
      '',
      kind,
      status,
      OpenTelemetry::Trace::INVALID_SPAN_ID,
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
