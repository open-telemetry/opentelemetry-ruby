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

  describe 'exporter with failure' do
    let(:exporter) { TestExporter.new(status_codes: [FAILURE]) }
    let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

    it 'logs export failure as error' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:error, nil, [/Unable to export metrics/])

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

  describe 'exporter with timeout' do
    let(:exporter) { TestExporter.new(status_codes: [TIMEOUT]) }
    let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

    it 'logs export timeout as error' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:error, nil, [/Export operation timed out/])

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

  describe 'exporter with empty metrics collection' do
    let(:exporter) { TestExporter.new }
    let(:reader) { PeriodicMetricReader.new(exporter: exporter) }

    it 'logs when collected_metrics is empty' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:debug, nil, [/No metrics to export/])

      reader.stub(:collect, []) do
        OpenTelemetry.stub(:logger, mock_logger) do
          reader.force_flush
        end
      end

      reader.shutdown
      mock_logger.verify
    end
  end
end
