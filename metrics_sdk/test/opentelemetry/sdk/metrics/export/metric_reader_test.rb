# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::MetricReader do
  export = OpenTelemetry::SDK::Metrics::Export

  let(:reader) { export::MetricReader.new }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(reader)
  end

  def record_counter(value = 1)
    OpenTelemetry.meter_provider.meter('test').create_counter('counter').add(value)
  end

  describe '#collect' do
    it 'returns the collected metrics' do
      record_counter

      metrics = reader.collect

      _(metrics.size).must_equal 1
      _(metrics[0].name).must_equal 'counter'
      _(metrics[0].data_points[0].value).must_equal 1
    end

    it 'returns an empty array when there is nothing to collect' do
      _(reader.collect).must_equal []
    end

    it 'returns an empty array and logs a warning after shutdown' do
      log_stream = StringIO.new
      OpenTelemetry.logger = ::Logger.new(log_stream)
      record_counter
      reader.shutdown

      _(reader.collect).must_equal []
      _(log_stream.string).must_match(/MetricReader already shutdown, ignoring collect request/)
    end
  end

  describe '#shutdown' do
    it 'returns SUCCESS' do
      _(reader.shutdown).must_equal export::SUCCESS
    end

    it 'is invoked by the meter provider shutdown' do
      record_counter
      OpenTelemetry.meter_provider.shutdown

      _(reader.collect).must_equal []
    end
  end
end
