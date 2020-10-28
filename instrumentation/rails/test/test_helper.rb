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

# Global opentelemetry-sdk setup
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.add_span_processor span_processor
end

# Import the version specifc Rails configs and make the `build_app` method available
case Rails.version
when /^6\.0/
  require 'test_helpers/configs/rails6'
when /^5\.2/
  require 'test_helpers/configs/rails5'
end

# Create a globally available Rails app, this should be used in test unless
# specifically testing behaviour with different initialization configs.
DEFAULT_RAILS_APP = build_app
::Rails.application = DEFAULT_RAILS_APP
