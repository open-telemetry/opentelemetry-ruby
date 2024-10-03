# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::LogRecordLimits do
  let(:log_record_limits) { OpenTelemetry::SDK::Logs::LogRecordLimits.new }

  describe '#initialize' do
    it 'provides defaults' do
      _(log_record_limits.attribute_count_limit).must_equal 128
      _(log_record_limits.attribute_length_limit).must_be_nil
    end

    it 'prioritizes specific environment varibles for attribute value length limits' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '35',
                                          'OTEL_LOG_RECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33') do
        _(log_record_limits.attribute_length_limit).must_equal 33
      end
    end

    it 'uses general attribute value length limits in the absence of more specific ones' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '35') do
        _(log_record_limits.attribute_length_limit).must_equal 35
      end
    end

    it 'reflects environment variables' do
      OpenTelemetry::TestHelpers.with_env('OTEL_LOG_RECORD_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_LOG_RECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32') do
        _(log_record_limits.attribute_count_limit).must_equal 1
        _(log_record_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'reflects explicit overrides' do
      OpenTelemetry::TestHelpers.with_env('OTEL_LOG_RECORD_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_LOG_RECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '4') do
        log_record_limits = OpenTelemetry::SDK::Logs::LogRecordLimits.new(attribute_count_limit: 10,
                                                                          attribute_length_limit: 32)
        _(log_record_limits.attribute_count_limit).must_equal 10
        _(log_record_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'reflects generic attribute env vars' do
      OpenTelemetry::TestHelpers.with_env('OTEL_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32') do
        _(log_record_limits.attribute_count_limit).must_equal 1
        _(log_record_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'prefers model-specific attribute env vars over generic attribute env vars' do
      OpenTelemetry::TestHelpers.with_env('OTEL_LOG_RECORD_ATTRIBUTE_COUNT_LIMIT' => '1',
                                          'OTEL_ATTRIBUTE_COUNT_LIMIT' => '2',
                                          'OTEL_LOG_RECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '32',
                                          'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' => '33') do
        _(log_record_limits.attribute_count_limit).must_equal 1
        _(log_record_limits.attribute_length_limit).must_equal 32
      end
    end

    it 'raises if attribute_count_limit is not positive' do
      assert_raises ArgumentError do
        OpenTelemetry::SDK::Logs::LogRecordLimits.new(attribute_count_limit: -1)
      end
    end

    it 'raises if attribute_length_limit is less than 32' do
      assert_raises ArgumentError do
        OpenTelemetry::SDK::Logs::LogRecordLimits.new(attribute_length_limit: 31)
      end
    end
  end
end
