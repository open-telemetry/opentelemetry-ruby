# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Zipkin::Transformer do
  Transformer = OpenTelemetry::Exporter::Zipkin::Transformer

  it 'encodes a span_data but not resource' do
    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo', 'bar_not_copied' => 'baz_not_capied')
    encoded_span = Transformer.to_zipkin_span(create_span_data(attributes: { 'bar' => 'baz' }), resource)
    _(encoded_span[:name]).must_equal('')
    _(encoded_span['localEndpoint']['serviceName']).must_equal('foo')
    _(encoded_span['tags']).must_equal('bar' => 'baz', 'otel.library.version' => '0.0.0', 'otel.library.name' => 'vendorlib')
  end

  it 'encodes span.status and span.kind' do
    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
    span_data = create_span_data(attributes: { 'bar' => 'baz' }, status: OpenTelemetry::Trace::Status.error, kind: :server)

    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    _(encoded_span['tags'].size).must_equal(5)

    kind_tag = encoded_span['kind']
    error_tag = encoded_span['tags']['error']

    _(kind_tag).must_equal('SERVER')
    _(error_tag).must_equal('')
  end

  it 'encodes attributes in events and the span' do
    attributes = { 'akey' => 'avalue', 'bar' => 'baz' }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        'event_with_attribs', { 'ekey' => 'evalue' }, exportable_timestamp
      ),
      OpenTelemetry::SDK::Trace::Event.new(
        'event_no_attrib', {}, exportable_timestamp
      )
    ]

    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    annotation_one = encoded_span[:annotations].first
    annotation_two = encoded_span[:annotations][1]

    _(annotation_one[:timestamp]).must_equal((events[0].timestamp / 1_000).to_s)
    _(annotation_one[:value]).must_equal({ 'event_with_attribs' => { 'ekey' => 'evalue' } }.to_json)

    _(annotation_two[:timestamp]).must_equal((events[1].timestamp / 1_000).to_s)
    _(annotation_two[:value]).must_equal('event_no_attrib')

    tags = encoded_span['tags']
    _(tags).must_equal('akey' => 'avalue', 'bar' => 'baz', 'otel.library.version' => '0.0.0', 'otel.library.name' => 'vendorlib')
  end

  it 'encodes array attribute values in events and the span as JSON strings' do
    attributes = { 'akey' => ['avalue'], 'bar' => 'baz' }
    events = [
      OpenTelemetry::SDK::Trace::Event.new(
        'event_with_attribs', { 'ekey' => ['evalue'] }, exportable_timestamp
      )
    ]

    resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
    span_data = create_span_data(attributes: attributes, events: events)
    encoded_span = Transformer.to_zipkin_span(span_data, resource)

    annotation_one = encoded_span[:annotations].first

    _(annotation_one[:timestamp]).must_equal((events[0].timestamp / 1000).to_s)
    _(annotation_one[:value]).must_equal({ 'event_with_attribs' => { 'ekey' => '["evalue"]' } }.to_json)

    tags = encoded_span['tags']
    _(tags).must_equal('akey' => ['avalue'].to_s, 'bar' => 'baz', 'otel.library.version' => '0.0.0', 'otel.library.name' => 'vendorlib')
  end

  describe 'status' do
    it 'encodes status code as strings' do
      status = OpenTelemetry::Trace::Status.ok

      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
      span_data = create_span_data(attributes: { 'bar' => 'baz' }, status: status)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      tags = encoded_span['tags']
      _(tags).must_equal('otel.status_code' => 'OK', 'bar' => 'baz', 'otel.library.version' => '0.0.0', 'otel.library.name' => 'vendorlib')
    end

    it 'encodes error status code as strings on error tag and status description field' do
      error_description = 'there is as yet insufficient data for a meaningful answer'
      status = OpenTelemetry::Trace::Status.error(error_description)
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
      span_data = create_span_data(attributes: { 'bar' => 'baz' }, status: status)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      tags = encoded_span['tags']
      _(tags).must_equal('error' => error_description, 'otel.status_code' => 'ERROR', 'bar' => 'baz', 'otel.library.version' => '0.0.0', 'otel.library.name' => 'vendorlib')
    end
  end

  describe 'instrumentation library' do
    it 'encodes library and version when set' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib', '0.1.0')
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
      span_data = create_span_data(attributes: { 'bar' => 'baz' }, instrumentation_library: lib)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      _(encoded_span['tags'].size).must_equal(3)
      _(encoded_span['tags']['otel.library.name']).must_equal('mylib')
      _(encoded_span['tags']['otel.library.version']).must_equal('0.1.0')
    end

    it 'skips nil values' do
      lib = OpenTelemetry::SDK::InstrumentationLibrary.new('mylib')
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'foo')
      span_data = create_span_data(attributes: { 'bar' => 'baz' }, instrumentation_library: lib)
      encoded_span = Transformer.to_zipkin_span(span_data, resource)

      _(encoded_span['tags'].size).must_equal(3)
      _(encoded_span['tags']['otel.library.name']).must_equal('mylib')
    end
  end
end
