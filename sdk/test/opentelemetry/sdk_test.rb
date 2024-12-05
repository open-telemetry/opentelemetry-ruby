# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    after { OpenTelemetry::TestHelpers.reset_opentelemetry }

    it 'logs the original error when a configuration error occurs' do
      received_exception = nil
      received_message = nil
      OpenTelemetry.error_handler = lambda do |exception: nil, message: nil|
        received_exception = exception
        received_message = message
      end

      OpenTelemetry::SDK.configure do |config|
        # This fails due to an invalid argument.
        config.add_span_processor(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(nil, invalid_option: 'foo'))
      end

      _(received_exception).must_be_instance_of OpenTelemetry::SDK::ConfigurationError
      _(received_message).must_match(/unexpected configuration error due to unknown keyword: .*invalid_option/)
    end
  end

  describe '#configure (sdk disabled)' do
    it 'ignore configuration when sdk is disabled by env' do
      config = OpenTelemetry::TestHelpers.with_env('OTEL_SDK_DISABLED' => 'true') do
        OpenTelemetry::SDK.configure        
      end
      _(config).must_equal nil
    end
  end
end
