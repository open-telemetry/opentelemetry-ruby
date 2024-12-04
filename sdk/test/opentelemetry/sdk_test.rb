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

  describe '#configure (no-op)' do
    before do
      ENV['OTEL_SDK_DISABLED'] = 'true'
    end

    after do
      ENV.delete('OTEL_SDK_DISABLED')
    end

    it 'logs a warning and generate a no-op tracer if env OTEL_SDK_DISABLED is defined' do
      tracer = OpenTelemetry::SDK.configure
      _(tracer).must_be_instance_of OpenTelemetry::Internal::ProxyTracer
    end
  end
end
