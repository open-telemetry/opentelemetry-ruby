# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'manticore'

require 'bundler/setup'
require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'pry'


Bundler.require

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Manticore'
  c.add_span_processor(span_processor)
  c.service_name = 'spec test'
end
