# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'faraday'

require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
sdk = OpenTelemetry::SDK
exporter = sdk::Trace::Export::InMemorySpanExporter.new
span_processor = sdk::Trace::Export::SimpleSpanProcessor.new(exporter)
OpenTelemetry.tracer_factory = sdk::Trace::TracerFactory.new.tap do |factory|
  factory.add_span_processor(span_processor)
end

EXPORTER = exporter