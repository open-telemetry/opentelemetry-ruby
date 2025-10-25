# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader do
  PeriodicMetricReader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader
  SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Metrics::Export::FAILURE
  TIMEOUT = OpenTelemetry::SDK::Metrics::Export::TIMEOUT

  class TestExporter
    def initialize(status_codes: nil)
      @status_codes = status_codes || []
      @exported_metrics = []
    end

    attr_reader :exported_metrics

    def export(metrics, timeout: nil)
      # If status codes are empty, return success for less verbose testing
      s = @status_codes.shift
      if s.nil? || s == SUCCESS
        @exported_metrics.concat(metrics)
        SUCCESS
      else
        s
      end
    end

    def shutdown(timeout: nil)
      SUCCESS
    end

    def force_flush(timeout: nil)
      SUCCESS
    end
  end

  class RaisingExporter
    def export(metrics, timeout: nil)
      raise 'boom!'
    end

    def shutdown(timeout: nil)
      SUCCESS
    end

    def force_flush(timeout: nil)
      SUCCESS
    end
  end

  describe 'faulty exporter' do
    it 'reports export failures' do
      skip if Gem.win_platform?

      exporter = TestExporter.new(status_codes: [FAILURE])
      periodic_metric_reader = PeriodicMetricReader.new(
        exporter: exporter,
        export_interval_millis: 60_000, # Long interval so we control when export happens
        export_timeout_millis: 5000
      )

      mock_logger = Minitest::Mock.new
      mock_logger.expect(:error, nil, [/Unable to export/])
      mock_logger.expect(:error, nil, [/Result code: 1/])

      # Stub collect to return a non-empty array so export is actually called
      periodic_metric_reader.stub(:collect, ['mock_metric']) do
        OpenTelemetry.stub(:logger, mock_logger) do
          # Call export directly to trigger the report_result method
          periodic_metric_reader.send(:export)
        end
      end

      periodic_metric_reader.shutdown
      mock_logger.verify
    end

    it 'reports successful exports' do
      skip if Gem.win_platform?

      exporter = TestExporter.new(status_codes: [SUCCESS])
      periodic_metric_reader = PeriodicMetricReader.new(
        exporter: exporter,
        export_interval_millis: 60_000, # Long interval so we control when export happens
        export_timeout_millis: 5000
      )

      mock_logger = Minitest::Mock.new
      mock_logger.expect(:debug, nil, ['Successfully exported metrics'])

      # Stub collect to return a non-empty array so export is actually called
      periodic_metric_reader.stub(:collect, ['mock_metric']) do
        OpenTelemetry.stub(:logger, mock_logger) do
          # Call export directly to trigger the report_result method
          periodic_metric_reader.send(:export)
        end
      end

      periodic_metric_reader.shutdown
      mock_logger.verify
    end
  end
end
