# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::LoggerProvider do
  let(:logger_provider) { OpenTelemetry::SDK::Logs::LoggerProvider.new }
  let(:mock_log_record_processor)  { Minitest::Mock.new }
  let(:mock_log_record_processor2) { Minitest::Mock.new }

  describe 'resource association' do
    let(:resource) { OpenTelemetry::SDK::Resources::Resource.create('hi' => 1) }
    let(:logger_provider) do
      OpenTelemetry::SDK::Logs::LoggerProvider.new(resource: resource)
    end

    it 'allows a resource to be associated with the logger provider' do
      assert_instance_of(
        OpenTelemetry::SDK::Resources::Resource, logger_provider.resource
      )
    end
  end

  describe '#add_log_record_processor' do
    it "adds the processor to the logger provider's processors" do
      assert_equal(0, logger_provider.instance_variable_get(:@log_record_processors).length)

      logger_provider.add_log_record_processor(mock_log_record_processor)
      assert_equal(1, logger_provider.instance_variable_get(:@log_record_processors).length)
    end

    describe 'when stopped' do
      before { logger_provider.instance_variable_set(:@stopped, true) }

      it 'does not add the processor' do
        assert_equal(0, logger_provider.instance_variable_get(:@log_record_processors).length)

        logger_provider.add_log_record_processor(mock_log_record_processor)
        assert_equal(0, logger_provider.instance_variable_get(:@log_record_processors).length)
      end

      it 'logs a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          logger_provider.add_log_record_processor(mock_log_record_processor)
          assert_match(/calling LoggerProvider#add_log_record_processor after shutdown/,
                       log_stream.string)
        end
      end
    end
  end

  describe '#logger' do
    let(:error_text) { /LoggerProvider#logger called with an invalid name/ }

    it 'logs a warning if name is nil' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        logger_provider.logger(name: nil)
        assert_match(error_text, log_stream.string)
      end
    end

    it 'logs a warning if name is an empty string' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        logger_provider.logger(name: '')
        assert_match(error_text, log_stream.string)
      end
    end

    it 'sets version to an empty string if nil' do
      # :version is nil by default, but explicitly setting it here
      # to make the test easier to read
      logger = logger_provider.logger(name: 'name', version: nil)
      assert_equal(logger.instance_variable_get(:@instrumentation_scope).version, '')
    end

    it 'creates a new logger with the passed-in name and version' do
      name = 'name'
      version = 'version'
      logger = logger_provider.logger(name: name, version: version)
      assert_equal(logger.instance_variable_get(:@instrumentation_scope).name, name)
      assert_equal(logger.instance_variable_get(:@instrumentation_scope).version, version)
    end
  end

  describe '#shutdown' do
    it 'logs a warning if called twice' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        logger_provider.shutdown
        assert logger_provider.instance_variable_get(:@stopped)
        assert_empty(log_stream.string)
        logger_provider.shutdown
        assert_match(/.* called multiple times/, log_stream.string)
      end
    end

    it 'sends shutdown to the processor' do
      mock_log_record_processor.expect(:shutdown, nil, timeout: nil)
      logger_provider.add_log_record_processor(mock_log_record_processor)
      logger_provider.shutdown
      mock_log_record_processor.verify
    end

    it 'sends shutdown to multiple processors' do
      mock_log_record_processor.expect(:shutdown, nil, timeout: nil)
      mock_log_record_processor2.expect(:shutdown, nil, timeout: nil)

      logger_provider.instance_variable_set(
        :@log_record_processors,
        [mock_log_record_processor, mock_log_record_processor2]
      )
      logger_provider.shutdown

      mock_log_record_processor.verify
      mock_log_record_processor2.verify
    end

    it 'does not allow subsequent shutdown attempts to reach the processor' do
      mock_log_record_processor.expect(:shutdown, nil, timeout: nil)

      logger_provider.add_log_record_processor(mock_log_record_processor)
      logger_provider.shutdown
      logger_provider.shutdown

      mock_log_record_processor.verify
    end

    it 'returns a timeout code if the countdown reaches zero' do
      OpenTelemetry::Common::Utilities.stub :maybe_timeout, 0 do
        logger_provider.add_log_record_processor(mock_log_record_processor)
        assert_equal(OpenTelemetry::SDK::Logs::Export::TIMEOUT, logger_provider.shutdown)
      end
    end
  end

  describe '#force_flush' do
    it 'notifies the log record processor' do
      mock_log_record_processor.expect(:force_flush, nil, timeout: nil)

      logger_provider.add_log_record_processor(mock_log_record_processor)
      logger_provider.force_flush

      mock_log_record_processor.verify
    end

    it 'supports multiple log record processors' do
      mock_log_record_processor.expect(:force_flush, nil, timeout: nil)
      mock_log_record_processor2.expect(:force_flush, nil, timeout: nil)

      logger_provider.add_log_record_processor(mock_log_record_processor)
      logger_provider.add_log_record_processor(mock_log_record_processor2)
      logger_provider.force_flush

      mock_log_record_processor.verify
      mock_log_record_processor2.verify
    end

    it 'returns a success status code if called while stopped' do
      logger_provider.add_log_record_processor(mock_log_record_processor)
      logger_provider.instance_variable_set(:@stopped, true)
      assert_equal(OpenTelemetry::SDK::Logs::Export::SUCCESS, logger_provider.force_flush)
    end

    it 'returns a timeout code when the timeout countdown reaches zero' do
      OpenTelemetry::Common::Utilities.stub :maybe_timeout, 0 do
        logger_provider.add_log_record_processor(mock_log_record_processor)
        assert_equal(OpenTelemetry::SDK::Logs::Export::TIMEOUT, logger_provider.force_flush)
      end
    end
  end
end
