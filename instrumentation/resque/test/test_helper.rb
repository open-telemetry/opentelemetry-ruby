# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'resque'
require 'opentelemetry/sdk'

require 'pry'
require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

redis_options = {}
redis_options[:password] = ENV['TEST_REDIS_PASSWORD'] || 'passw0rd'
redis_options[:host] = ENV['TEST_REDIS_HOST'] || '127.0.0.1'
redis_options[:port] = ENV['TEST_REDIS_PORT'] || '16379'
Resque.redis = redis_options
