# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'redis'

require 'opentelemetry/sdk'

require 'minitest/autorun'

ENV['TEST_REDIS_HOST'] ||= '127.0.0.1'
ENV['TEST_REDIS_PORT'] ||= '16379'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
