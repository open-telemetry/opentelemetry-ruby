# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'pry'
require 'mongo'

require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

class Module
  include Minitest::Spec::DSL
end

module TestHelper
  extend self

  def setup_mongo
    Mongo::Logger.logger.level = ::Logger::WARN
    client
  end

  def teardown_mongo
    client.database.drop
  end

  def client
    @client ||= Mongo::Client.new(["#{host}:#{port}"], database: database)
  end

  def database
    'otel_test'
  end

  def host
    ENV.fetch('TEST_MONGODB_HOST', '127.0.0.1')
  end

  def port
    ENV.fetch('TEST_MONGODB_PORT', 27_017).to_i
  end
end
