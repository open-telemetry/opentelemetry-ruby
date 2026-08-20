# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir do
  let(:reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: max_size) }
  let(:max_size) { 4 }
  let(:context) do
    ::OpenTelemetry::Trace.context_with_span(
      ::OpenTelemetry::Trace.non_recording_span(
        ::OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array('77cb6ccc522d310611014dd6ecbb70036a').pack('H*'),
          span_id: Array('31e175128efc4018').pack('H*'),
          trace_flags: ::OpenTelemetry::Trace::TraceFlags::DEFAULT
        )
      )
    )
  end
  let(:timestamp) { 123_456_789 }
  let(:attributes) { { 'key' => 'value' } }

  describe '#initialize' do
    it 'uses DEFAULT_SIZE when max_size is not provided' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
      100.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }
      exemplars = reservoir.collect
      _(exemplars.size).must_equal Etc.nprocessors
    end

    it 'respects the provided max_size' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 2)
      3.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }
      exemplars = reservoir.collect
      _(exemplars.size).must_equal 2
    end
  end

  describe '#offer' do
    it 'stores correct exemplar data and uses reservoir sampling when exceeding max_size' do
      (max_size * 3).times { |i| reservoir.offer(value: i, timestamp: timestamp + i, attributes: attributes, context: context) }
      exemplars = reservoir.collect

      _(exemplars.size).must_equal max_size

      exemplars.each do |exemplar|
        _(exemplar).must_be_kind_of OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
        _(exemplar.value).must_be :<, max_size * 3
        _(exemplar.time_unix_nano).must_equal(timestamp + exemplar.value)
        _(exemplar.span_id.unpack1('H*')).must_equal '31e175128efc4018'
        _(exemplar.trace_id.unpack1('H*')).must_equal '77cb6ccc522d310611014dd6ecbb70036a'
      end
    end
  end

  describe '#collect' do
    it 'returns empty array when no exemplars offered' do
      exemplars = reservoir.collect
      _(exemplars).must_equal []
    end

    it 'filters collected attributes already present on a point' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: { 'shared' => 'value', 'unique' => 'keep' }, context: context)

      exemplars = reservoir.collect(attributes: { 'shared' => 'value' })

      _(exemplars.size).must_equal 1
      _(exemplars.first.filtered_attributes).must_equal({ 'unique' => 'keep' })
    end

    it 'resets measurement counter for delta temporality' do
      max_size.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars.size).must_equal max_size

      _(reservoir.collect(aggregation_temporality: :delta)).must_equal []

      reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = reservoir.collect
      _(exemplars[0].value).must_equal 100
    end
  end
end
