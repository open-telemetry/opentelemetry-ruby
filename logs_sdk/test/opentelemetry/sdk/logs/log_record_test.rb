# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::LogRecord do
  Logs = OpenTelemetry::SDK::Logs
  let(:log_record) { Logs::LogRecord.new(**args) }
  let(:args) { {} }
  let(:logger) { Logs::Logger.new('', '', Logs::LoggerProvider.new) }

  describe '#initialize' do
    describe 'observed_timestamp' do
      describe 'when observed_timestamp is present' do
        let(:current_time) { Time.now }
        let(:observed_timestamp) { current_time + 1 }
        let(:args) { { observed_timestamp: observed_timestamp } }

        it 'is equal to observed_timestamp' do
          assert_equal(observed_timestamp, log_record.observed_timestamp)
        end

        it 'is not equal to timestamp' do
          refute_equal(log_record.timestamp, log_record.observed_timestamp)
        end

        it 'is not equal to the current time' do
          refute_equal(current_time, log_record.observed_timestamp)
        end
      end

      describe 'when timestamp is present' do
        let(:timestamp) { Time.now }
        let(:args) { { timestamp: timestamp } }

        it 'is equal to timestamp' do
          assert_equal(timestamp, log_record.observed_timestamp)
        end
      end

      describe 'when observed_timestamp and timestamp are nil' do
        let(:args) { { timestamp: nil, observed_timestamp: nil } }

        it 'is not nil' do
          refute_nil(log_record.observed_timestamp)
        end

        it 'is equal to the current time' do
          # Since I can't get the current time when the test was run
          # I'm going to assert it's an Integer, which is the
          # Process.clock_gettime return value class when passed the
          # :nanosecond option
          assert_instance_of(Time, log_record.observed_timestamp)
        end
      end
    end

    describe '#to_log_record_data' do
      let(:args) do
        span_context = OpenTelemetry::Trace::SpanContext.new
        {
          timestamp: Time.now,
          observed_timestamp: Time.now + 1,
          severity_text: 'DEBUG',
          severity_number: 0,
          body: 'body',
          attributes: { 'a' => 'b' },
          trace_id: span_context.trace_id,
          span_id: span_context.span_id,
          trace_flags: span_context.trace_flags,
          resource: logger.instance_variable_get(:@logger_provider).instance_variable_get(:@resource),
          instrumentation_scope: logger.instance_variable_get(:@instrumentation_scope)
        }
      end

      it 'transforms the LogRecord into a LogRecordData' do
        log_record_data = log_record.to_log_record_data

        assert_equal(args[:timestamp].strftime('%s%N').to_i, log_record_data.timestamp)
        assert_equal(args[:observed_timestamp].strftime('%s%N').to_i, log_record_data.observed_timestamp)
        assert_equal(args[:severity_text], log_record_data.severity_text)
        assert_equal(args[:severity_number], log_record_data.severity_number)
        assert_equal(args[:body], log_record_data.body)
        assert_equal(args[:attributes], log_record_data.attributes)
        assert_equal(args[:trace_id], log_record_data.trace_id)
        assert_equal(args[:span_id], log_record_data.span_id)
        assert_equal(args[:trace_flags], log_record_data.trace_flags)
        assert_equal(args[:resource], log_record_data.resource)
        assert_equal(args[:instrumentation_scope], log_record_data.instrumentation_scope)
      end
    end

    describe 'attribute limits' do
      it 'uses the limits set by the logger provider via the logger' do
        # Spy on the console output
        captured_stdout = StringIO.new
        original_stdout = $stdout
        $stdout = captured_stdout

        # Create the LoggerProvider with the console exporter and an attribute limit of 1
        limits = Logs::LogRecordLimits.new(attribute_count_limit: 1)
        logger_provider = Logs::LoggerProvider.new(log_record_limits: limits)
        console_exporter = Logs::Export::SimpleLogRecordProcessor.new(Logs::Export::ConsoleLogRecordExporter.new)
        logger_provider.add_log_record_processor(console_exporter)

        # Create a logger that uses the given LoggerProvider
        logger = Logs::Logger.new('', '', logger_provider)

        # Emit a log from that logger, with attribute count exceeding the limit
        logger.on_emit(attributes: { 'a' => 'a', 'b' => 'b' })

        # Look at the captured output to see if the attributes have been truncated
        assert_match(/attributes={"b"=>"b"}/, captured_stdout.string)
        refute_match(/"a"=>"a"/, captured_stdout.string)

        # Return STDOUT to its normal output
        $stdout = original_stdout
      end

      it 'emits an error message if attribute key is invalid' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          logger.on_emit(attributes: { a: 'a' })
          assert_match(/invalid log record attribute key type Symbol/, log_stream.string)
        end
      end

      it 'emits an error message if the attribute value is invalid' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          logger.on_emit(attributes: { 'a' => Class.new })
          assert_match(/invalid log record attribute value type Class/, log_stream.string)
        end
      end

      it 'uses the default limits if none provided' do
        log_record = Logs::LogRecord.new
        default = Logs::LogRecordLimits::DEFAULT

        assert_equal(default.attribute_count_limit, log_record.instance_variable_get(:@log_record_limits).attribute_count_limit)
        # default length is nil
        assert_nil(log_record.instance_variable_get(:@log_record_limits).attribute_length_limit)
      end

      it 'trims the oldest attributes' do
        limits = Logs::LogRecordLimits.new(attribute_count_limit: 1)
        attributes = { 'old' => 'old', 'new' => 'new' }
        log_record = Logs::LogRecord.new(log_record_limits: limits, attributes: attributes)

        assert_equal({ 'new' => 'new' }, log_record.attributes)
      end
    end

    describe 'attribute value limit' do
      it 'truncates the values that are too long' do
        length_limit = 32
        too_long = 'a' * (length_limit + 1)
        just_right = 'a' * (length_limit - 3) # truncation removes 3 chars for the '...'
        limits = Logs::LogRecordLimits.new(attribute_length_limit: length_limit)
        log_record = Logs::LogRecord.new(log_record_limits: limits, attributes: { 'key' => too_long })

        assert_equal({ 'key' => "#{just_right}..." }, log_record.attributes)
      end

      it 'does not alter values within the range' do
        length_limit = 32
        within_range = 'a' * length_limit
        limits = Logs::LogRecordLimits.new(attribute_length_limit: length_limit)
        log_record = Logs::LogRecord.new(log_record_limits: limits, attributes: { 'key' => within_range })

        assert_equal({ 'key' => within_range }, log_record.attributes)
      end
    end
  end
end
