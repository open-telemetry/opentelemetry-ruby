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

    _(encoded_span[:tags].size).must_equal(4)

    kind_tag = encoded_span[:kind]
    error_tag = encoded_span[:tags]['error']

    _(kind_tag).must_equal('SERVER')
    _(error_tag).must_equal('true')
  end

  # TODO

  it 'encodes attributes in events and the span' do
  end

  describe 'instrumentation library' do
    it 'encodes library and version when set' do
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
