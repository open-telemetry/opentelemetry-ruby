# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'kafka'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'

require 'pry'
require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
SPAN_PROCESSOR = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor SPAN_PROCESSOR
end

def wait_for(max_attempts: 10, retry_delay: 0.10, error_message:)
  attempts = 0
  while attempts < max_attempts
    return if yield

    attempts += 1
    raise error_message if attempts >= max_attempts

    sleep retry_delay
  end
end
