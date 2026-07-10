# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    export = OpenTelemetry::SDK::Metrics::Export

    let(:captured_stdout) { StringIO.new }
    let(:metric_data1) { OpenTelemetry::SDK::Metrics::State::MetricData.new({ name: 'name1' }) }
    let(:metric_data2) { OpenTelemetry::SDK::Metrics::State::MetricData.new({ name: 'name2' }) }
    let(:metrics)      { [metric_data1, metric_data2] }
    let(:exporter)     { export::ConsoleMetricPullExporter.new }

    before do
      reset_metrics_sdk
      @original_stdout = $stdout
      $stdout = captured_stdout
    end

    after do
      $stdout = @original_stdout
    end

    it 'accepts an Array of MetricData as arg to #export and succeeds' do
      _(exporter.export(metrics)).must_equal export::SUCCESS
    end

    it 'accepts an Enumerable of MetricData as arg to #export and succeeds' do
      enumerable = Struct.new(:metric0, :metric1).new(metrics[0], metrics[1])

      _(exporter.export(enumerable)).must_equal export::SUCCESS
    end

    it 'outputs to console on export (stdout)' do
      exporter.export(metrics)

      _(captured_stdout.string).must_match(/#<struct OpenTelemetry::SDK::Metrics::State::MetricData/)
    end

    it 'outputs to console using pull (stdout)' do
      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(exporter)
      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })
      exporter.pull

      output = captured_stdout.string

      _(output).wont_be_empty
      _(output).must_match(/name="counter"/)
      _(output).must_match(/unit="smidgen"/)
      _(output).must_match(/description="a small amount of something"/)
      _(output).must_match(/OpenTelemetry::SDK::InstrumentationScope name="test"/)
      _(output).must_match(/#<struct OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint/)
    end

    it 'accepts calls to #force_flush' do
      exporter.force_flush
    end

    it 'accepts calls to #shutdown' do
      exporter.shutdown
    end

    it 'fails to export after shutdown' do
      exporter.shutdown

      _(exporter.export(metrics)).must_equal export::FAILURE
    end

    describe 'cardinality limit' do
      it 'accepts cardinality_limit parameter on initialization' do
        exporter_with_limit = export::ConsoleMetricPullExporter.new(aggregation_cardinality_limit: 100)
        _(exporter_with_limit.export(metrics)).must_equal export::SUCCESS
      end

      it 'enforces cardinality limit when collecting metrics' do
        exporter_with_limit = export::ConsoleMetricPullExporter.new(aggregation_cardinality_limit: 2)

        OpenTelemetry::SDK.configure
        OpenTelemetry.meter_provider.add_metric_reader(exporter_with_limit)
        meter = OpenTelemetry.meter_provider.meter('test')
        counter = meter.create_counter('test_counter')

        # Add more data points than the cardinality limit
        counter.add(1, attributes: { 'key' => 'a' })
        counter.add(2, attributes: { 'key' => 'b' })
        counter.add(3, attributes: { 'key' => 'c' }) # Should trigger overflow

        exporter_with_limit.pull

        # Check that overflow attribute is present in output
        _(captured_stdout.string).must_match(/otel\.metric\.overflow.*true/)
      end
    end
  end
end
