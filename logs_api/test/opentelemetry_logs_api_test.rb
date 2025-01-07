# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry do
  class CustomLogRecord < OpenTelemetry::Logs::LogRecord
  end

  class CustomLogger < OpenTelemetry::Logs::Logger
    def on_emit(*)
      CustomLogRecord.new
    end
  end

  class CustomLoggerProvider < OpenTelemetry::Logs::LoggerProvider
    def logger(name = nil, version = nil)
      CustomLogger.new
    end
  end

  describe '.logger_provider' do
    after do
      # Ensure we don't leak custom logger factories and loggers to other tests
      OpenTelemetry.logger_provider = OpenTelemetry::Internal::ProxyLoggerProvider.new
    end

    it 'returns a Logs::LoggerProvider by default' do
      logger_provider = OpenTelemetry.logger_provider
      _(logger_provider).must_be_kind_of(OpenTelemetry::Logs::LoggerProvider)
    end

    it 'returns the same instance when accessed multiple times' do
      _(OpenTelemetry.logger_provider).must_equal(OpenTelemetry.logger_provider)
    end

    it 'returns user-specified logger provider' do
      custom_logger_provider = CustomLoggerProvider.new
      OpenTelemetry.logger_provider = custom_logger_provider
      _(OpenTelemetry.logger_provider).must_equal(custom_logger_provider)
    end
  end

  describe '.logger_provider=' do
    after do
      # Ensure we don't leak custom logger factories and loggers to other tests
      OpenTelemetry.logger_provider = OpenTelemetry::Internal::ProxyLoggerProvider.new
    end

    it 'has a default proxy logger' do
      refute_nil OpenTelemetry.logger_provider.logger
    end

    it 'upgrades default loggers to *real* loggers' do
      # proxy loggers do not emit any log records, nor does the API logger
      # the on_emit method is empty
      default_logger = OpenTelemetry.logger_provider.logger
      _(default_logger.on_emit(body: 'test')).must_be_instance_of(NilClass)
      OpenTelemetry.logger_provider = CustomLoggerProvider.new
      _(default_logger.on_emit(body: 'test')).must_be_instance_of(CustomLogRecord)
    end

    it 'upgrades the default logger provider to a *real* logger provider' do
      default_logger_provider = OpenTelemetry.logger_provider
      OpenTelemetry.logger_provider = CustomLoggerProvider.new
      _(default_logger_provider.logger).must_be_instance_of(CustomLogger)
    end
  end
end
