# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::ExemplarBucket do
  let(:bucket) { OpenTelemetry::SDK::Metrics::Exemplar::ExemplarBucket.new }
  let(:valid_context) do
    ::OpenTelemetry::Trace.context_with_span(
      ::OpenTelemetry::Trace.non_recording_span(
        ::OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array('77cb6ccc522d310611014dd6ecbb70036a').pack('H*'),
          span_id: Array('31e175128efc4018').pack('H*'),
          trace_flags: ::OpenTelemetry::Trace::TraceFlags::SAMPLED
        )
      )
    )
  end
  let(:invalid_context) { ::OpenTelemetry::Context.empty }
  let(:timestamp) { 123_456_789 }
  let(:attributes) { { 'key1' => 'value1', 'key2' => 'value2' } }
  let(:point_attributes) { { 'key2' => 'value2' } }

  describe '#offer' do
    it 'stores measurement with valid context' do
      bucket.offer(value: 42, time_unix_nano: timestamp, attributes: attributes, context: valid_context)

      exemplar = bucket.collect(point_attributes: {})
      _(exemplar).wont_be_nil
      _(exemplar.value).must_equal 42
      _(exemplar.time_unix_nano).must_equal timestamp
      _(exemplar.span_id.unpack1('H*')).must_equal '31e175128efc4018'
      _(exemplar.trace_id.unpack1('H*')).must_equal '77cb6ccc522d310611014dd6ecbb70036a'
      _(exemplar.filtered_attributes).must_equal({ 'key1' => 'value1', 'key2' => 'value2' })
    end

    it 'stores measurement with invalid context' do
      bucket.offer(value: 100, time_unix_nano: timestamp, attributes: attributes, context: invalid_context)

      exemplar = bucket.collect(point_attributes: {})
      _(exemplar).wont_be_nil
      _(exemplar.value).must_equal 100
      _(exemplar.span_id).must_be_nil
      _(exemplar.trace_id).must_be_nil
      _(exemplar.filtered_attributes).must_equal({ 'key1' => 'value1', 'key2' => 'value2' })
    end

    it 'overwrites previous measurement' do
      bucket.offer(value: 10, time_unix_nano: timestamp, attributes: { 'old' => 'data' }, context: valid_context)
      bucket.offer(value: 20, time_unix_nano: timestamp + 1000, attributes: { 'new' => 'data' }, context: valid_context)

      exemplar = bucket.collect(point_attributes: {})
      _(exemplar.value).must_equal 20
      _(exemplar.time_unix_nano).must_equal(timestamp + 1000)
      _(exemplar.filtered_attributes).must_equal({ 'new' => 'data' })
    end
  end

  describe '#collect' do
    it 'returns nil when nothing was offered' do
      exemplar = bucket.collect(point_attributes: {})
      _(exemplar).must_be_nil
    end

    it 'filters out point attributes from exemplar attributes' do
      bucket.offer(value: 42, time_unix_nano: timestamp, attributes: attributes, context: valid_context)

      exemplar = bucket.collect(point_attributes: point_attributes)
      _(exemplar.filtered_attributes).must_equal({ 'key1' => 'value1' })
    end

    it 'handles nil attributes' do
      bucket.offer(value: 42, time_unix_nano: timestamp, attributes: nil, context: valid_context)

      exemplar = bucket.collect(point_attributes: {})
      _(exemplar.filtered_attributes).must_be_nil
    end

    it 'resets bucket after collection and maintains separate state across cycles' do
      # First cycle
      bucket.offer(value: 100, time_unix_nano: timestamp, attributes: { 'cycle' => '1' }, context: valid_context)
      exemplar1 = bucket.collect(point_attributes: {})
      _(exemplar1.value).must_equal 100
      _(exemplar1.filtered_attributes).must_equal({ 'cycle' => '1' })

      # After collection, bucket should be empty
      _(bucket.collect(point_attributes: {})).must_be_nil

      # Second cycle with different values
      bucket.offer(value: 200, time_unix_nano: timestamp + 5000, attributes: { 'cycle' => '2' }, context: valid_context)
      exemplar2 = bucket.collect(point_attributes: {})
      _(exemplar2.value).must_equal 200
      _(exemplar2.filtered_attributes).must_equal({ 'cycle' => '2' })

      # Values should be different
      _(exemplar1.value).wont_equal exemplar2.value
    end
  end
end
