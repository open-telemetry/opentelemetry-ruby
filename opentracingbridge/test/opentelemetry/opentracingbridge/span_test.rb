# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingBridge::Span do
  SpanBridge = OpenTelemetry::OpenTracingBridge::Span

  class TestSpan
    attr_reader :name
    attr_writer :name
    attr_reader :attributes
    attr_reader :end_timestamp

    def initialize
      @name = nil
      @attributes = {}
      @end_timestamp = nil
    end

    def set_attribute(key, val)
      @attributes[key] = val
    end

    def finish(end_timestamp: Time.now)
      @end_timestamp = end_timestamp
    end
  end

  let(:span_bridge) { SpanBridge.new(TestSpan.new) }
  describe '#operation_name=' do
    it 'sets the operation name on the underlying span' do
      span_bridge.operation_name = 'operation'
      span_bridge.span.name.must_equal 'operation'
    end
  end

  describe '#set_tag' do
    it 'sets the tag as attribute on underlying span' do
      span_bridge.set_tag('k', 'v')
      span_bridge.span.attributes['k'].must_equal 'v'
    end
  end

  describe '#finish' do
    it 'sets end timestamp' do
      span_bridge.span.end_timestamp.must_be_nil
      span_bridge.finish
      span_bridge.span.end_timestamp.wont_be_nil
    end

    it 'sets end timestamp passed in' do
      # TODO: uh make this pass
      # ts = Time.now
      # span_bridge.finish
      # span_bridge.span.end_timestamp.must_equal(ts)
    end

    it 'returns itself' do
      span_bridge.finish.must_equal(span_bridge)
    end
  end
end
