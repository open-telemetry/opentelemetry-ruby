# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Logs::LogRecordData do
  LOGS = OpenTelemetry::SDK::Logs

  describe 'unix_nano_timestamp' do
    it 'does not error if given a non-time object' do
      data = OpenTelemetry::SDK::Logs::LogRecordData.new(timestamp: 'fake')

      assert_nil data.unix_nano_timestamp
    end

    it 'converts the object to integer' do
      time = Time.now
      data = OpenTelemetry::SDK::Logs::LogRecordData.new(timestamp: time)

      assert_instance_of Integer, data.unix_nano_timestamp
    end
  end

  describe 'unix_nano_observed_timestamp' do
    it 'does not error if given a non-time object' do
      data = OpenTelemetry::SDK::Logs::LogRecordData.new(observed_timestamp: 'fake')

      assert_nil data.unix_nano_observed_timestamp
    end

    it 'converts the object to integer' do
      data = OpenTelemetry::SDK::Logs::LogRecordData.new(observed_timestamp: Time.now)

      assert_instance_of Integer, data.unix_nano_observed_timestamp
    end
  end
end
