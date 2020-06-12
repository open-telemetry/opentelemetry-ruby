# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporters::Datadog::Exporter::SpanEncoder do
  let(:span_encoder) { OpenTelemetry::Exporters::Datadog::Exporter::SpanEncoder.new }

  it 'encodes a span_data' do
    encoded_span = span_encoder.translate_to_datadog([create_span_data()], 'example_service')
    _(encoded_span[0].to_hash[:name]).must_equal('example_name')
    _(encoded_span[0].to_hash[:meta]).must_equal({"_dd_origin"=>""})
  end

  it 'encodes attributes in the span but not the events' do
    attributes = { 'akey' => 'avalue' }
    events = [
      OpenTelemetry::Trace::Event.new(
        name: 'event', attributes: { 'ekey' => 'evalue' }
      )
    ]

    span_data = create_span_data(attributes: attributes, events: events)
    encoded_spans = span_encoder.translate_to_datadog([span_data], 'example_service')
    datadog_span_info = encoded_spans[0]

    _(datadog_span_info.get_tag("akey")).must_equal('avalue')
    assert_nil(datadog_span_info.get_tag("ekey"))
  end

  it 'encodes array attribute values in the span as JSON strings' do
    attributes = { 'akey' => ["avalue"] }

    span_data = create_span_data(attributes: attributes)
    encoded_spans = span_encoder.translate_to_datadog([span_data], 'example_service')
    datadog_span_info = encoded_spans[0]

    _(datadog_span_info.get_tag("akey")).must_equal('["avalue"]')
  end

  it 'generates a valid datadog resource' do
    attributes = { 'http.method' => 'GET', 'http.route' => "/example/api" }

    span_data = create_span_data(attributes: attributes)
    encoded_spans = span_encoder.translate_to_datadog([span_data], 'example_service')
    datadog_span_info = encoded_spans[0]

    _(datadog_span_info.resource).must_equal('GET /example/api')    
  end

  it 'translates otel spans to datadog spans' do
    span_names = ("test1", "test2", "test3")
    trace_id = 0x6E0C63257DE34C926F9EFCD03927272E
    trace_id_low = 0x6F9EFCD03927272E
    span_id = 0x34BF92DEEFC58C92
    parent_id = 0x1111111111111111
    other_id = 0x2222222222222222
    base_time = 683647322 * 10 ** 9
    start_times = [base_time, base_time + 150 * 10 ** 6, base_time + 300 * 10 ** 6]
    durations = [50 * 10 ** 6, 100 * 10 ** 6, 200 * 10 ** 6]
    end_times = [ start_times[0] + durations[0], start_times[1] + durations[1], start_times[2] + durations[2] ]
  end

  # it 'generates a valid datadog span type' do
  # end

  # it 'sets a valid datadog error, message, and type' do
  # end

  # it 'sets origin' do
  # end  

  def create_span_data(attributes: nil, events: nil, links: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT)
    OpenTelemetry::SDK::Trace::SpanData.new(
      'example_name',
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
      trace_flags
    )
  end
end
