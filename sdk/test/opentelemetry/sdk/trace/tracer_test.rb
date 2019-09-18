# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Tracer do
  Tracer = OpenTelemetry::SDK::Trace::Tracer

  let(:tracer) { Tracer.new }

  describe '#create_event' do
    it 'trims event attributes' do
      tracer.active_trace_config = TraceConfig.new(max_attributes_per_event: 1)
      event = tracer.create_event(name: 'event', attributes: { '1' => 1, '2' => 2 })
      event.attributes.size.must_equal(1)
    end
  end

  describe '#create_link' do
    it 'trims link attributes' do
      tracer.active_trace_config = TraceConfig.new(max_attributes_per_link: 1)
      link = tracer.create_link(SpanContext.new, '1' => 1, '2' => 2)
      link.attributes.size.must_equal(1)
    end
  end

  describe '#initialize' do
    # TODO
  end

  describe '#shutdown' do
    # TODO
  end

  describe '#add_span_processor' do
    # TODO
  end

  describe '#start_root_span' do
    # TODO
  end

  describe '#start_span' do
    # TODO
  end
end
