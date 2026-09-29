# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader do
  PeriodicMetricReader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader
  SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS

  class TestExporter
    def initialize(status_codes: nil, force_flush_status: SUCCESS, shutdown_status: SUCCESS)
      @status_codes = status_codes || []
      @exported_metrics = []
      @force_flush_status = force_flush_status
      @shutdown_status = shutdown_status
      @force_flush_count = 0
    end

    attr_reader :exported_metrics, :force_flush_count, :force_flush_timeout

    def export(metrics, timeout: nil)
      s = @status_codes.shift
      if s.nil? || s == SUCCESS
        @exported_metrics.concat(metrics)
        SUCCESS
      else
        s
      end
    end

    def shutdown(timeout: nil) = @shutdown_status

    def force_flush(timeout: nil)
      @force_flush_count += 1
      @force_flush_timeout = timeout
      @force_flush_status
    end
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

  describe 'collection status' do
    collection_result = OpenTelemetry::SDK::Metrics::Export::CollectionResult
    export = OpenTelemetry::SDK::Metrics::Export

    let(:exporter) { TestExporter.new }
    let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

    after { reader.shutdown }

    it 'does not export when collection fails' do
      failed = collection_result.new([], export::FAILURE)

      reader.stub(:collect_with_result, failed) do
        _(reader.send(:export)).must_equal export::FAILURE
      end

      _(exporter.exported_metrics).must_be_empty
    end

    it 'warns and still exports the collected metrics when collection times out' do
      timed_out = collection_result.new(['mock_metric'], export::TIMEOUT)

      with_test_logger do |log_stream|
        reader.stub(:collect_with_result, timed_out) do
          _(reader.force_flush).must_equal export::TIMEOUT
        end

        _(log_stream.string).must_match(/Timed out while collecting metrics/)
      end
      _(exporter.exported_metrics).must_equal ['mock_metric']
    end

    it 'exports the collected metrics when collection succeeds' do
      succeeded = collection_result.new(['mock_metric'], export::SUCCESS)

      reader.stub(:collect_with_result, succeeded) do
        _(reader.send(:export)).must_equal export::SUCCESS
      end

      _(exporter.exported_metrics).must_equal ['mock_metric']
    end

    it 'passes the export timeout to collection' do
      captured_timeout = nil
      collect_stub = lambda do |timeout:|
        captured_timeout = timeout
        collection_result.new([], export::SUCCESS)
      end

      reader.stub(:collect_with_result, collect_stub) { reader.force_flush(timeout: 5) }

      _(captured_timeout).must_equal 5
    end
  end

  describe '#force_flush status' do
    export = OpenTelemetry::SDK::Metrics::Export

    after { reader.shutdown }

    describe 'when the export fails' do
      let(:exporter) { TestExporter.new(status_codes: [export::FAILURE]) }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it 'returns FAILURE' do
        reader.stub(:collect, ['mock_metric']) { _(reader.force_flush).must_equal export::FAILURE }
      end
    end

    describe 'when the export times out' do
      let(:exporter) { TestExporter.new(status_codes: [export::TIMEOUT]) }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it 'returns TIMEOUT' do
        reader.stub(:collect, ['mock_metric']) { _(reader.force_flush).must_equal export::TIMEOUT }
      end
    end

    describe "when the exporter's force_flush fails" do
      let(:exporter) { TestExporter.new(force_flush_status: export::FAILURE) }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it 'returns FAILURE even though the export succeeded' do
        reader.stub(:collect, ['mock_metric']) { _(reader.force_flush).must_equal export::FAILURE }
        _(exporter.exported_metrics).must_equal ['mock_metric']
      end
    end

    describe "when both the export and the exporter's force_flush fail" do
      let(:exporter) { TestExporter.new(status_codes: [export::TIMEOUT], force_flush_status: export::FAILURE) }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it 'returns the most severe result' do
        reader.stub(:collect, ['mock_metric']) { _(reader.force_flush).must_equal export::TIMEOUT }
      end
    end

    describe 'when a timeout is given' do
      let(:exporter) { TestExporter.new }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it "passes the timeout to the exporter's force_flush" do
        reader.stub(:collect, ['mock_metric']) { reader.force_flush(timeout: 5) }
        _(exporter.force_flush_timeout).must_equal 5
      end
    end

    describe 'when there is nothing to export' do
      let(:exporter) { TestExporter.new }
      let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

      it "returns SUCCESS and still calls the exporter's force_flush" do
        reader.stub(:collect, []) { _(reader.force_flush).must_equal export::SUCCESS }
        _(exporter.force_flush_count).must_equal 1
      end
    end
  end

  describe '#shutdown status' do
    export = OpenTelemetry::SDK::Metrics::Export

    it "returns FAILURE when the exporter's shutdown fails" do
      reader = PeriodicMetricReader.new(exporter: TestExporter.new(shutdown_status: export::FAILURE))

      _(reader.shutdown).must_equal export::FAILURE
    end

    it "returns FAILURE when the exporter's force_flush fails" do
      reader = PeriodicMetricReader.new(exporter: TestExporter.new(force_flush_status: export::FAILURE))

      _(reader.shutdown).must_equal export::FAILURE
    end

    it 'treats an exporter that reports no status as SUCCESS' do
      reader = PeriodicMetricReader.new(exporter: TestExporter.new(force_flush_status: nil, shutdown_status: nil))

      _(reader.shutdown).must_equal export::SUCCESS
    end
  end
end
