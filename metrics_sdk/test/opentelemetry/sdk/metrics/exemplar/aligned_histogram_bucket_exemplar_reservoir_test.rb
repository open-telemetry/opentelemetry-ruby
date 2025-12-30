# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir do
  let(:boundaries) { [0, 5, 10, 25, 50, 75, 100] }
  let(:reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: boundaries) }
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
    it 'uses default boundaries when not provided' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new
      reservoir.offer(value: -1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 6, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = reservoir.collect
      _(exemplars.size).must_be :>=, 3
    end

    it 'accepts custom boundaries' do
      custom_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [10, 20, 30])
      custom_reservoir.offer(value: 5, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 15, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 25, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 35, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = custom_reservoir.collect
      _(exemplars.size).must_equal 4
    end
  end

  describe '#offer' do
    it 'places exemplars in correct buckets and stores correct exemplar data' do
      reservoir.offer(value: -5, timestamp: timestamp, attributes: nil, context: context)
      reservoir.offer(value: 3, timestamp: timestamp + 1, attributes: nil, context: context)
      reservoir.offer(value: 7, timestamp: timestamp + 2, attributes: nil, context: context)
      reservoir.offer(value: 15, timestamp: timestamp + 3, attributes: nil, context: context)
      reservoir.offer(value: 30, timestamp: timestamp + 4, attributes: nil, context: context)
      reservoir.offer(value: 60, timestamp: timestamp + 5, attributes: nil, context: context)
      reservoir.offer(value: 90, timestamp: timestamp + 6, attributes: nil, context: context)
      reservoir.offer(value: 150, timestamp: timestamp + 7, attributes: nil, context: context)

      exemplars = reservoir.collect

      _(exemplars.size).must_equal 8

      expected_values = [-5, 3, 7, 15, 30, 60, 90, 150]
      exemplars.each_with_index do |exemplar, i|
        _(exemplar).must_be_kind_of OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
        _(exemplar.value).must_equal expected_values[i]
        _(exemplar.time_unix_nano).must_equal timestamp + i
        _(exemplar.filtered_attributes).must_be_nil
        _(exemplar.span_id.unpack1('H*')).must_equal '31e175128efc4018'
        _(exemplar.trace_id.unpack1('H*')).must_equal '77cb6ccc522d310611014dd6ecbb70036a'
      end
    end

    it 'stores one exemplar per bucket with reservoir sampling' do
      20.times { |i| reservoir.offer(value: 1 + (i * 0.1), timestamp: timestamp + i, attributes: { 'iteration' => i }, context: context) }

      exemplars = reservoir.collect

      bucket_1_exemplars = exemplars.select { |e| e.value > 0 && e.value <= 5 }
      _(bucket_1_exemplars.size).must_equal 1
      _(bucket_1_exemplars[0].value).must_be :>, 0
      _(bucket_1_exemplars[0].value).must_be :<=, 5
    end
  end

  describe '#collect' do
    it 'returns empty array when no exemplars offered' do
      exemplars = reservoir.collect
      _(exemplars).must_equal []
    end

    it 'filters collected attributes already present on a point' do
      reservoir.offer(value: 3, timestamp: timestamp, attributes: { 'shared' => 'value', 'bucket' => 'keep' }, context: context)

      exemplars = reservoir.collect(attributes: { 'shared' => 'value' })

      _(exemplars.size).must_equal 1
      _(exemplars.first.filtered_attributes).must_equal({ 'bucket' => 'keep' })
    end

    it 'resets exemplars after collection' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars.size).must_equal 2

      _(reservoir.collect(aggregation_temporality: :delta)).must_equal []
    end
  end

  describe 'edge cases' do
    it 'handles single boundary correctly' do
      single_boundary_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [10])

      single_boundary_reservoir.offer(value: 5, timestamp: timestamp, attributes: { 'below' => 'true' }, context: context)
      single_boundary_reservoir.offer(value: 15, timestamp: timestamp, attributes: { 'above' => 'true' }, context: context)

      exemplars = single_boundary_reservoir.collect

      _(exemplars.size).must_equal 2
      _(exemplars[0].value).must_equal 5
      _(exemplars[1].value).must_equal 15
    end

    it 'handles empty boundaries gracefully' do
      empty_boundary_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [])

      empty_boundary_reservoir.offer(value: -100, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 0, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = empty_boundary_reservoir.collect

      _(exemplars.size).must_equal 1
    end
  end
end
