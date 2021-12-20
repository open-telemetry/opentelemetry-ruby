# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

ENV['OTEL_LOG_LEVEL'] ||= 'fatal'

require 'trilogy'
require 'opentelemetry/sdk'
require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'pry'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
