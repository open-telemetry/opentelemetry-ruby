# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rack'

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

### "un-patch" Rack::Builder:
#
require 'rack/builder'
UNTAINTED_RACK_BUILDER = ::Rack::Builder.dup

module SafeRackBuilder
  def after_setup
    super
    ::Rack.send(:remove_const, :Builder)
    ::Rack.const_set(:Builder, UNTAINTED_RACK_BUILDER.dup)
  end

  def after_teardown
    super
    Rack.send(:remove_const, :Builder)
    Rack.const_set(:Builder, UNTAINTED_RACK_BUILDER.dup)
  end
end

module Minitest
  class Test
    include SafeRackBuilder
  end
end
