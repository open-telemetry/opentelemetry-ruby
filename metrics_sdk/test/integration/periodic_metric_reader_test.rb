# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'json'

describe OpenTelemetry::SDK do
  describe '#periodic_metric_reader' do
    before { reset_metrics_sdk }

    # OTLP cannot export a metric without data points
    it 'does not export metrics without data points' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      meter.create_histogram('example', unit: 's', description: 'test')

      sleep(1)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      assert_empty snapshot
    end

    it 'does not export metrics without data points when they have a view' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      boundaries = [0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]

      OpenTelemetry.meter_provider.add_view('http.server.request.duration',
                                            type: :histogram,
                                            aggregation: OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(boundaries: boundaries))

      meter = OpenTelemetry.meter_provider.meter('test')
      meter.create_histogram('http.server.request.duration', unit: 's', description: 'Duration of HTTP server requests.')

      sleep(8)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      assert_empty snapshot
    end

    it 'emits 2 metrics after 10 seconds' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })

      sleep(8)

      counter.add(5)
      counter.add(6)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      _(snapshot.size).must_equal(2)

      _(snapshot[0].name).must_equal('counter')
      _(snapshot[0].unit).must_equal('smidgen')
      _(snapshot[0].description).must_equal('a small amount of something')

      _(snapshot[0].instrumentation_scope.name).must_equal('test')

      _(snapshot[0].data_points[0].value).must_equal(1)
      _(snapshot[0].data_points[0].attributes).must_equal({})

      _(snapshot[0].data_points[1].value).must_equal(4)
      _(snapshot[0].data_points[1].attributes).must_equal('a' => 'b')

      _(snapshot[0].data_points[2].value).must_equal(3)
      _(snapshot[0].data_points[2].attributes).must_equal('b' => 'c')

      _(snapshot[0].data_points[3].value).must_equal(4)
      _(snapshot[0].data_points[3].attributes).must_equal('d' => 'e')

      _(snapshot[1].data_points.size).must_equal(1)
      _(snapshot[1].data_points[0].value).must_equal(11)

      _(periodic_metric_reader.instance_variable_get(:@thread).alive?).must_equal false
    end

    it 'emits 1 metric after 1 second when interval is > 1 second' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })

      sleep(1)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      _(snapshot.size).must_equal(1)
      _(periodic_metric_reader.instance_variable_get(:@thread).alive?).must_equal false
    end

    unless Gem.win_platform? || %w[jruby truffleruby].include?(RUBY_ENGINE) # forking is not available on these platforms or runtimes
      it 'is restarted after forking' do
        OpenTelemetry::SDK.configure

        metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
        periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

        OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

        read, write = IO.pipe

        pid = fork do
          meter = OpenTelemetry.meter_provider.meter('test')
          counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

          counter.add(1)
          counter.add(2, attributes: { 'a' => 'b' })
          counter.add(2, attributes: { 'a' => 'b' })
          counter.add(3, attributes: { 'b' => 'c' })
          counter.add(4, attributes: { 'd' => 'e' })

          sleep(8)
          snapshot = metric_exporter.metric_snapshots

          json = snapshot.map { |reading| { name: reading.name } }.to_json
          write.puts json
        end

        Timeout.timeout(10) do
          Process.waitpid(pid)
        end

        periodic_metric_reader.shutdown
        snapshot = JSON.parse(read.gets.chomp)
        _(snapshot.size).must_equal(1)
        _(snapshot[0]).must_equal('name' => 'counter')
        _(periodic_metric_reader.instance_variable_get(:@thread).alive?).must_equal false
      end
    end

    it 'shutdown break the export interval cycle' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 1_000_000, export_timeout_millis: 10_000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      _(periodic_metric_reader.alive?).must_equal true

      sleep 5 # make sure the work thread start

      Timeout.timeout(2) do # Fail if this block takes more than 2 seconds
        periodic_metric_reader.shutdown
      end

      _(periodic_metric_reader.alive?).must_equal false
    end
  end
end
