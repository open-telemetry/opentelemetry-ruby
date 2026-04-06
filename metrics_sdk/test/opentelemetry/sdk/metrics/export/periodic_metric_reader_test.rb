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
end
