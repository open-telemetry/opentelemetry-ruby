# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Sum do
  let(:sum_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: aggregation_temporality) }
  let(:now_in_nano) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:aggregation_temporality) { :delta }

  it 'aggregates and collects' do
    sum_aggregation.update(1, {})
    sum_aggregation.update(2, {})

    sum_aggregation.update(2, 'foo' => 'bar')
    sum_aggregation.update(2, 'foo' => 'bar')

    ndps = sum_aggregation.collect(now_in_nano, now_in_nano)
    _(ndps[0].value).must_equal(3)
    _(ndps[0].attributes).must_equal({})

    _(ndps[1].value).must_equal(4)
    _(ndps[1].attributes).must_equal('foo' => 'bar')
  end

  it 'does not aggregate between collects' do
    sum_aggregation.update(1, {})
    sum_aggregation.update(2, {})
    ndps = sum_aggregation.collect(now_in_nano, now_in_nano)

    sum_aggregation.update(1, {})
    # Assert that the recent update does not
    # impact the already collected metrics
    _(ndps[0].value).must_equal(3)

    ndps = sum_aggregation.collect(now_in_nano, now_in_nano)
    # Assert that we are not accumulating values
    # between calls to collect
    _(ndps[0].value).must_equal(1)
  end

  describe 'when aggregation_temporality is not delta' do
    let(:aggregation_temporality) { :not_delta }

    it 'allows metrics to accumulate' do
      sum_aggregation.update(1, {})
      sum_aggregation.update(2, {})
      ndps = sum_aggregation.collect(now_in_nano, now_in_nano)

      sum_aggregation.update(1, {})
      # Assert that the recent update does not
      # impact the already collected metrics
      _(ndps[0].value).must_equal(3)

      ndps = sum_aggregation.collect(now_in_nano, now_in_nano)
      # Assert that we are accumulating values
      # and not just capturing the delta since
      # the previous collect call
      _(ndps[0].value).must_equal(4)
    end
  end
end
