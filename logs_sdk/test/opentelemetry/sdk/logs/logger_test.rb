# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::Logger do
  let(:logger_provider) { OpenTelemetry::SDK::Logs::LoggerProvider.new }
  let(:logger) { logger_provider.logger(name: 'default_logger') }

  describe '#on_emit' do
    it 'creates a new LogRecord' do
      output = 'chocolate cherry'
      OpenTelemetry::SDK::Logs::LogRecord.stub(:new, ->(_) { puts output }) do
        assert_output(/#{output}/) { logger.on_emit }
      end
    end

    it 'sends the newly-created log record to the processors' do
      mock_log_record = Minitest::Mock.new
      mock_context = Minitest::Mock.new
      def mock_context.value(key); OpenTelemetry::Trace::Span::INVALID; end # rubocop:disable Style/SingleLineMethods

      OpenTelemetry::SDK::Logs::LogRecord.stub(:new, ->(_) { mock_log_record }) do
        mock_log_record_processor = Minitest::Mock.new
        logger_provider.add_log_record_processor(mock_log_record_processor)
        mock_log_record_processor.expect(:on_emit, nil, [mock_log_record, mock_context])
        logger.on_emit(context: mock_context)
        mock_log_record_processor.verify
      end
    end

    describe 'when the provider has no processors' do
      it 'does not error' do
        logger_provider.instance_variable_set(:@log_record_processors, [])
        assert(logger.on_emit)
      end
    end
  end
end
