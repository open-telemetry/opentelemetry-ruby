# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rails'

require 'opentelemetry/sdk'

require 'pry'
require 'minitest/autorun'
require 'rack/test'

require_relative '../lib/opentelemetry/instrumentation'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.add_span_processor span_processor
end

case Rails.version
when /^6\.0/
  require 'test_helpers/configs/rails6'
when /^5\.2/
  require 'test_helpers/configs/rails5'
end

require 'action_controller/railtie'
require 'test_helpers/middlewares'
::Rails.application.initialize!
require 'test_helpers/routes'
require 'test_helpers/controllers'
