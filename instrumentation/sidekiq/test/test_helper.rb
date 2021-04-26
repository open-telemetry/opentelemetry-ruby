# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'minitest/autorun'
require 'pry'

require 'sidekiq'
require 'sidekiq/testing'
require 'helpers/mock_loader'

ENV['TEST_REDIS_HOST'] ||= '127.0.0.1'
ENV['TEST_REDIS_PORT'] ||= '16379'

require 'opentelemetry/sdk'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

redis_url = "redis://#{ENV['TEST_REDIS_HOST']}:#{ENV['TEST_REDIS_PORT']}/0"

Sidekiq.configure_server do |config|
  config.redis = { password: 'passw0rd', url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { password: 'passw0rd', url: redis_url }
end
