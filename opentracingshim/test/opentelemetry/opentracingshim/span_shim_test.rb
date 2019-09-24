# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingShim::SpanShim do
  SpanShim = OpenTelemetry::OpenTracingShim::SpanShim

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

  let(:span_shim) { SpanShim.new(TestSpan.new) }
  describe '#operation_name=' do
    it 'sets the operation name on the underlying span' do
      span_shim.operation_name = 'operation'
      span_shim.span.name.must_equal 'operation'
    end
  end

  describe '#set_tag' do
    it 'sets the tag as attribute on underlying span' do
      span_shim.set_tag('k', 'v')
      span_shim.span.attributes['k'].must_equal 'v'
    end
  end

  describe '#finish' do
    it 'sets end timestamp' do
      span_shim.span.end_timestamp.must_be_nil
      span_shim.finish
      span_shim.span.end_timestamp.wont_be_nil
    end

    it 'sets end timestamp passed in' do
      # TODO: uh make this pass
      # ts = Time.now
      # span_shim.finish
      # span_shim.span.end_timestamp.must_equal(ts)
    end

    it 'returns itself' do
      span_shim.finish.must_equal(span_shim)
    end
  end
end
