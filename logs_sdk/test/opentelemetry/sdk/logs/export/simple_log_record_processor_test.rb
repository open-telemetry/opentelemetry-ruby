# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor do
  let(:exporter) { OpenTelemetry::SDK::Logs::Export::LogRecordExporter.new }
  let(:processor) { OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(exporter) }
  let(:log_record) { OpenTelemetry::SDK::Logs::LogRecord.new }
  let(:mock_context) { Minitest::Mock.new }

  describe '#initialize' do
    it 'raises an error when exporter is invalid' do
      OpenTelemetry::Common::Utilities.stub(:valid_exporter?, false) do
        assert_raises(ArgumentError) { OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(exporter) }
      end
    end
  end

  describe '#on_emit' do
    it 'exports the log records' do
      mock_exporter = Minitest::Mock.new
      processor.instance_variable_set(:@log_record_exporter, mock_exporter)
      mock_log_record_data = Minitest::Mock.new

      log_record.stub(:to_log_record_data, mock_log_record_data) do
        OpenTelemetry::Common::Utilities.stub(:valid_exporter?, true) do
          mock_exporter.expect(:export, OpenTelemetry::SDK::Logs::Export::SUCCESS, [[mock_log_record_data]])
          processor.on_emit(log_record, mock_context)
          mock_exporter.verify
        end
      end
    end

    it 'does not export if stopped' do
      processor.instance_variable_set(:@stopped, true)
      # raise if export is invoked
      exporter.stub(:export, ->(_) { raise 'whoops!' }) do
        processor.on_emit(log_record, mock_context)
      end
    end

    it 'does not export if log_record is nil' do
      # raise if export is invoked
      exporter.stub(:export, ->(_) { raise 'whoops!' }) do
        processor.on_emit(nil, mock_context)
      end
    end

    it 'does not raise if exporter is nil' do
      processor.instance_variable_set(:@log_record_exporter, nil)
      processor.on_emit(log_record, mock_context)
    end

    it 'catches and logs exporter errors' do
      error_message = 'uh oh'
      logger_mock = Minitest::Mock.new
      logger_mock.expect(:error, nil, [/#{error_message}/])
      # raise if exporter's emit call is invoked
      OpenTelemetry.stub(:logger, logger_mock) do
        exporter.stub(:export, ->(_) { raise error_message }) do
          processor.on_emit(log_record, mock_context)
        end
      end

      logger_mock.verify
    end
  end

  describe '#force_flush' do
    it 'does not attempt to flush if stopped' do
      processor.instance_variable_set(:@stopped, true)
      # raise if export is invoked
      exporter.stub(:force_flush, ->(_) { raise 'whoops!' }) do
        processor.force_flush
      end
    end

    it 'returns success when the exporter cannot be found' do
      processor.instance_variable_set(:@log_record_exporter, nil)
      assert_equal(OpenTelemetry::SDK::Logs::Export::SUCCESS, processor.force_flush)
    end

    it 'calls #force_flush on the exporter' do
      exporter = Minitest::Mock.new
      processor.instance_variable_set(:@log_record_exporter, exporter)
      exporter.expect(:force_flush, nil, timeout: nil)
      processor.force_flush
      exporter.verify
    end
  end

  describe '#shutdown' do
    it 'does not attempt to shutdown if stopped' do
      processor.instance_variable_set(:@stopped, true)
      # raise if export is invoked
      exporter.stub(:shutdown, ->(_) { raise 'whoops!' }) do
        processor.shutdown
      end
    end

    describe 'when exporter is nil' do
      it 'returns success' do
        processor.instance_variable_set(:@log_record_exporter, nil)
        assert_equal(OpenTelemetry::SDK::Logs::Export::SUCCESS, processor.shutdown)
      end

      it 'sets stopped to true' do
        processor.instance_variable_set(:@log_record_exporter, nil)
        processor.shutdown
        assert(processor.instance_variable_get(:@stopped))
      end
    end

    it 'calls shutdown on the exporter' do
      exporter = Minitest::Mock.new
      processor.instance_variable_set(:@log_record_exporter, exporter)
      exporter.expect(:shutdown, nil, timeout: nil)
      processor.shutdown
      exporter.verify
    end

    it 'sets stopped to true after calling shutdown on the exporter' do
      exporter = Minitest::Mock.new
      processor.instance_variable_set(:@log_record_exporter, exporter)
      exporter.expect(:shutdown, nil, timeout: nil)
      processor.shutdown
      assert(processor.instance_variable_get(:@stopped))
    end
  end
end
