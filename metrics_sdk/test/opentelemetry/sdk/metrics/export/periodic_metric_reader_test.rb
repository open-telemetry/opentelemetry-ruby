# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader do
  PeriodicMetricReader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader
  SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS

  class TestExporter
    def initialize(status_codes: nil)
      @status_codes = status_codes || []
      @exported_metrics = []
    end

    attr_reader :exported_metrics

    def export(metrics, timeout: nil)
      s = @status_codes.shift
      if s.nil? || s == SUCCESS
        @exported_metrics.concat(metrics)
        SUCCESS
      else
        s
      end
    end

    def shutdown(timeout: nil) = SUCCESS

    def force_flush(timeout: nil) = SUCCESS
  end

  describe 'succesful exporter' do
    let(:exporter) { TestExporter.new(status_codes: [SUCCESS]) }
    let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

    it 'logs successful export as debug' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:debug, nil, ['Successfully exported metrics'])

      # Stub collect to return a non-empty array so export is actually called
      reader.stub(:collect, ['mock_metric']) do
        OpenTelemetry.stub(:logger, mock_logger) do
          reader.force_flush
        end
      end

      reader.shutdown
      mock_logger.verify
    end
  end

  describe 'with metric producers' do
    class TimeoutRecordingExporter < TestExporter
      attr_reader :timeouts

      def initialize
        super
        @timeouts = []
      end

      def export(metrics, timeout: nil)
        @timeouts << timeout
        super
      end
    end

    # Advances a fake clock while producing, like a bridge that takes time to respond.
    class ClockAdvancingMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      attr_reader :timeouts

      def initialize(clock, duration)
        super(aggregation_temporality: :cumulative)
        @clock = clock
        @duration = duration
        @timeouts = []
      end

      def produce(resource:, metric_filter: nil, timeout: nil)
        @timeouts << timeout
        @clock[0] += @duration
        Result.new(metrics: [OpenTelemetry::SDK::Metrics::State::MetricData.new('producer_metric')], status: SUCCESS, errors: [])
      end
    end

    let(:clock) { [0.0] }
    let(:exporter) { TimeoutRecordingExporter.new }

    def build_reader(producer)
      PeriodicMetricReader.new(exporter: exporter, metric_producers: [producer], export_timeout_millis: 30_000)
    end

    def with_fake_clock(&)
      OpenTelemetry::Common::Utilities.stub(:timeout_timestamp, -> { clock[0] }, &)
    end

    it 'hands the force_flush timeout to producers and the remainder to the exporter' do
      producer = ClockAdvancingMetricProducer.new(clock, 0.5)
      reader = build_reader(producer)

      with_fake_clock { reader.force_flush(timeout: 2) }

      _(producer.timeouts).must_equal([2])
      _(exporter.timeouts.length).must_equal(1)
      _(exporter.timeouts[0]).must_be_within_delta(1.5, 1e-9)
    ensure
      reader&.shutdown
    end

    it 'shares the export timeout when force_flush is not given one' do
      producer = ClockAdvancingMetricProducer.new(clock, 0.5)
      reader = build_reader(producer)

      with_fake_clock { reader.force_flush }

      _(producer.timeouts).must_equal([30.0])
      _(exporter.timeouts.length).must_equal(1)
      _(exporter.timeouts[0]).must_be_within_delta(29.5, 1e-9)
    ensure
      reader&.shutdown
    end

    it 'skips the export when producers use up the timeout' do
      producer = ClockAdvancingMetricProducer.new(clock, 3)
      reader = build_reader(producer)
      handled = []

      with_fake_clock do
        OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
          reader.force_flush(timeout: 2)
        end
      end

      _(exporter.timeouts).must_be_empty
      _(handled.map(&:last)).must_equal(['PeriodicMetricReader timed out while collecting metrics; skipped exporting them.'])
    ensure
      reader&.shutdown
    end
  end
end
