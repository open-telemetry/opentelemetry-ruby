# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sidekiq'
require 'sidekiq/testing'
require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'helpers/mock_loader'
require 'active_job'
require 'pry'

# OpenTelemetry SDK config for testing
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

# Sidekiq redis configuration
ENV['TEST_REDIS_HOST'] ||= '127.0.0.1'
ENV['TEST_REDIS_PORT'] ||= '16379'

redis_url = "redis://#{ENV['TEST_REDIS_HOST']}:#{ENV['TEST_REDIS_PORT']}/0"

Sidekiq.configure_server do |config|
  config.redis = { password: 'passw0rd', url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { password: 'passw0rd', url: redis_url }
end

# Silence Actibe Job logging noise
ActiveJob::Base.logger = Logger.new('/dev/null')

class SimpleJobWithActiveJob < ActiveJob::Base
  self.queue_adapter = :sidekiq

  def perform(*args); end
end

# Test jobs
class SimpleEnqueueingJob
  include Sidekiq::Worker

  def perform
    SimpleJob.perform_async
  end
end

class SimpleJob
  include Sidekiq::Worker

  def perform; end
end

class BaggageTestingJob
  include Sidekiq::Worker

  def perform(*args)
    OpenTelemetry::Trace.current_span['success'] = true if OpenTelemetry::Baggage.value('testing_baggage') == 'it_worked'
  end
end

class ExceptionTestingJob
  include Sidekiq::Worker

  def perform(*args)
    raise 'a little hell'
  end
end
