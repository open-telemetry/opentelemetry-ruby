# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporters::Datadog::Exporter::SpanEncoder do
  # let(:span_encoder) { OpenTelemetry::Exporters::Datadog::Exporter::SpanEncoder.new }

  # it 'encodes a span_data' do
  # end

  # it 'encodes attributes in the span' do
  # end

  # it 'encodes array attribute values in events and the span as JSON strings' do
  # end

  # it 'translates otel spans to datadog spans' do
  # end

  # it 'generates a valid datadog resource' do
  # end

  # it 'generates a valid datadog span type' do
  # end

  # it 'sets a valid datadog error, message, and type' do
  # end

  # it 'sets origin' do
  # end  

  def create_span_data(attributes: nil, events: nil, links: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT)
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
      trace_flags
    )
  end
end
