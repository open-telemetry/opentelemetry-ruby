# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    after do
      # Ensure we don't leak custom loggers and error handlers to other tests
      OpenTelemetry.logger = Logger.new(File::NULL)
      OpenTelemetry.error_handler = nil
    end

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
end
