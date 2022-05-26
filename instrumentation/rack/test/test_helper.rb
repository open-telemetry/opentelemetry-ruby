# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rack'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'

require 'pry'
require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../lib/opentelemetry-instrumentation-rack'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
