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
        reader.stub(:collect_with_result, timed_out) { reader.force_flush }

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
end
