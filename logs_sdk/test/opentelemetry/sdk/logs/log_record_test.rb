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
        let(:observed_timestamp) { '1692661486.2841358' }
        let(:args) { { observed_timestamp: observed_timestamp } }

        it 'is equal to observed_timestamp' do
          assert_equal(observed_timestamp, log_record.observed_timestamp)
        end

        it 'is not equal to timestamp' do
          refute_equal(log_record.timestamp, log_record.observed_timestamp)
        end

        # Process.clock_gettime is used to set the current time
        # That method returns a Float. Since the stubbed value of
        # observed_timestamp is a String, we can know the the
        # observed_timestamp was not set to the value of Process.clock_gettime
        # by making sure its value is not a Float.
        it 'is not equal to the current time' do
          refute_instance_of(Float, log_record.observed_timestamp)
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
  end
end
