# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry do
  class CustomLogRecord < OpenTelemetry::Logs::LogRecord
  end

  class CustomLogger < OpenTelemetry::Logs::Logger
    attr_reader :emitted

    def on_emit(**args)
      @emitted = args
      CustomLogRecord.new
    end
  end

  class CustomLoggerProvider < OpenTelemetry::Logs::LoggerProvider
    attr_reader :requested

    def logger(name:, version: nil)
      @requested = { name: name, version: version }
      @logger ||= CustomLogger.new
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
      refute_nil OpenTelemetry.logger_provider.logger(name: 'component')
    end

    it 'upgrades default loggers to *real* loggers' do
      # proxy loggers do not emit any log records, nor does the API logger
      # the on_emit method is empty
      default_logger = OpenTelemetry.logger_provider.logger(name: 'component')
      _(default_logger.on_emit(body: 'test')).must_be_instance_of(NilClass)
      OpenTelemetry.logger_provider = CustomLoggerProvider.new
      _(default_logger.on_emit(body: 'test')).must_be_instance_of(CustomLogRecord)
    end

    it 'upgrades the default logger provider to a *real* logger provider' do
      default_logger_provider = OpenTelemetry.logger_provider
      OpenTelemetry.logger_provider = CustomLoggerProvider.new
      _(default_logger_provider.logger(name: 'component')).must_be_instance_of(CustomLogger)
    end

    it 'passes the instrumentation scope through when upgrading a proxy logger' do
      OpenTelemetry.logger_provider.logger(name: 'component', version: '1.0')
      custom_logger_provider = CustomLoggerProvider.new
      OpenTelemetry.logger_provider = custom_logger_provider
      _(custom_logger_provider.requested).must_equal(name: 'component', version: '1.0')
    end

    it 'forwards log record fields through an upgraded proxy logger' do
      proxy_logger = OpenTelemetry.logger_provider.logger(name: 'component')
      custom_logger_provider = CustomLoggerProvider.new
      OpenTelemetry.logger_provider = custom_logger_provider

      proxy_logger.on_emit(body: 'hello', severity_text: 'WARN', severity_number: 13)

      _(custom_logger_provider.logger(name: 'component').emitted).must_equal(
        timestamp: nil,
        observed_timestamp: nil,
        severity_number: 13,
        severity_text: 'WARN',
        body: 'hello',
        trace_id: nil,
        span_id: nil,
        trace_flags: nil,
        attributes: nil,
        event_name: nil,
        context: nil
      )
    end
  end
end
