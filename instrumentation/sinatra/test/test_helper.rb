# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sinatra'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'

require 'minitest/autorun'
require 'rack/test'

require_relative '../lib/opentelemetry-instrumentation-sinatra'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
