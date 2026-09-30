# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::MetricReader do
  export = OpenTelemetry::SDK::Metrics::Export

  let(:reader) { export::MetricReader.new }
  let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new }

  before { reset_metrics_sdk }

  describe '#collect' do
    it 'returns an Array of MetricData' do
      meter_provider.add_metric_reader(reader)
      meter_provider.meter('test').create_counter('counter').add(1)

      metrics = reader.collect

      _(metrics).must_be_kind_of Array
      _(metrics.first.name).must_equal 'counter'
    end
  end

  describe '#collect_with_result' do
    it 'reports SUCCESS with the collected metrics' do
      meter_provider.add_metric_reader(reader)
      meter_provider.meter('test').create_counter('counter').add(1)

      result = reader.collect_with_result

      _(result).must_be_kind_of export::CollectionResult
      _(result.status).must_equal export::SUCCESS
      _(result).must_be :success?
      _(result.metrics.map(&:name)).must_equal ['counter']
    end

    it 'reports SUCCESS for an empty collection' do
      result = reader.collect_with_result

      _(result.status).must_equal export::SUCCESS
      _(result.metrics).must_be_empty
    end

    it 'reports SUCCESS when collection finishes within the timeout' do
      result = reader.collect_with_result(timeout: 60)

      _(result).must_be :success?
    end

    it 'reports TIMEOUT and keeps the collected metrics when the timeout is exceeded' do
      meter_provider.add_metric_reader(reader)
      meter_provider.meter('test').create_counter('counter').add(1)

      result = reader.collect_with_result(timeout: 0)

      _(result.status).must_equal export::TIMEOUT
      _(result).must_be :timeout?
      _(result.metrics.map(&:name)).must_equal ['counter']
    end

    it 'reports FAILURE with no metrics and handles the error when collection raises' do
      handled = []
      OpenTelemetry.error_handler = ->(exception: nil, message: nil) { handled << [exception, message] }

      result = reader.stub(:collect, -> { raise 'boom' }) { reader.collect_with_result }

      _(result.status).must_equal export::FAILURE
      _(result).must_be :failure?
      _(result.metrics).must_equal []
      _(handled.size).must_equal 1
      _(handled.first[0].message).must_equal 'boom'
      _(handled.first[1]).must_equal 'Failed to collect metrics.'
    end

    it 'does not change what #collect returns' do
      meter_provider.add_metric_reader(reader)
      counter = meter_provider.meter('test').create_counter('counter')

      counter.add(1)
      _(reader.collect_with_result.metrics.first.data_points.first.value).must_equal 1

      counter.add(2)
      _(reader.collect.first.data_points.first.value).must_equal 3
    end
  end
end
