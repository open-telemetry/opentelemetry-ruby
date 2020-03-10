# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rack'

require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
