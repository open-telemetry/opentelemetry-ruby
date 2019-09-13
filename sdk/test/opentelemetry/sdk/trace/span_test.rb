# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Span do
  Span = OpenTelemetry::SDK::Trace::Span
  TraceConfig = OpenTelemetry::SDK::Trace::Config::TraceConfig
  NoopSpanProcessor = OpenTelemetry::SDK::Trace::NoopSpanProcessor
  SpanKind = OpenTelemetry::Trace::SpanKind

  let(:span) do
    context = SpanContext.new
    trace_config = TraceConfig.new(
      max_attributes_count: 1,
      max_events_count: 1,
      max_links_count: 1,
      max_attributes_per_event: 1,
      max_attributes_per_link: 1
    )
    span_processor = NoopSpanProcessor.instance
    Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
             span_processor, nil, nil, nil, Time.now)
  end

  describe '#recording_events?' do
    it 'returns true' do
      span.must_be :recording_events?
    end
  end

  describe '#set_attribute' do
    it 'sets an attribute' do
    end

    it 'trims the oldest attribute' do
    end

    it 'does not set an attribute if span is ended' do
    end

    it 'counts attributes' do
    end
  end

  describe '#add_event' do
  end

  describe '#add_link' do
  end

  describe '#status=' do
    it 'sets the status' do
    end

    it 'does not set the status if span is ended' do
    end
  end

  describe '#name=' do
    it 'sets the name' do
    end

    it 'does not set the name if span is ended' do
    end
  end

  describe '#finish' do
    it 'returns itself' do
    end

    it 'sets the end timestamp' do
    end

    it 'calls the span processor #on_end callback' do
    end

    it 'marks the span as ended' do
    end

    it 'does not allow ending more than once' do
    end
  end

  describe '#initialize' do
    it 'installs the span processor' do
    end

    it 'calls the span processor #on_start callback' do
    end

    it 'trims excess attributes' do
    end

    it 'counts events' do
    end

    it 'counts links' do
    end

    it 'counts attributes' do
    end

    it 'trims excess links' do
    end

    it 'trims excess events' do
    end
  end
end
