# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'
require 'rails'

require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'rack/test'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

# logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# Rails settings
ENV['RAILS_ENV'] = 'test'
