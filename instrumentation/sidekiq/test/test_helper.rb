# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'minitest/autorun'
require 'pry'

require 'sidekiq'
require 'sidekiq/testing'
require 'helpers/mock_loader'

require 'opentelemetry/sdk'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
